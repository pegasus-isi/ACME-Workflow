#!/usr/bin/env python
import sys
import string
from ConfigParser import ConfigParser
from Pegasus.DAX3 import *

DAXGEN_DIR = os.path.dirname(os.path.realpath(__file__))
TEMPLATE_DIR = os.path.join(DAXGEN_DIR, "templates")

def format_template(name, outfile, **kwargs):
    "This fills in the values for the template called 'name' and writes it to 'outfile'"
    templatefile = os.path.join(TEMPLATE_DIR, name)
    template = open(templatefile).read()
    formatter = string.Formatter()
    data = formatter.format(template, **kwargs)
    f = open(outfile, "w")
    try:
        f.write(data)
    finally:
        f.close()

class ACMEWorkflow(object):
    def __init__(self, outdir, config):
        "'outdir' is the directory where the workflow is written, and 'config' is a ConfigParser object"
        self.outdir = outdir
        self.config = config
        self.daxfile = os.path.join(self.outdir, "dax.xml")
        self.replicas = {}
        self.casename = config.get("acme", "casename")
        self.mppwidth = config.get("acme", "mppwidth")
        self.stop_option = config.get("acme", "stop_option")
        self.stop_n = [x.strip() for x in config.get("acme", "stop_n").split(",")]
        self.walltime = [x.strip() for x in config.get("acme", "walltime").split(",")]

        if len(self.stop_n) != len(self.walltime):
            raise Exception("stop_n should have the same number of entries as walltime")

    def generate_env(self):
        path = os.path.join(self.outdir, "env.sh")
        f = open(path, "w")
        try:
            f.write("CASENAME=%s" % self.casename)
        finally:
            f.close()

    def add_replica(self, name, path):
        "Add a replica entry to the replica catalog for the workflow"
        url = "file://%s" % path
        self.replicas[name] = url

    def generate_replica_catalog(self):
        "Write the replica catalog for this workflow to a file"
        path = os.path.join(self.outdir, "rc.txt")
        f = open(path, "w")
        try:
            for name, url in self.replicas.items():
                f.write('%-30s %-100s pool="local"\n' % (name, url))
        finally:
            f.close()

    def generate_transformation_catalog(self):
        "Write the transformation catalog for this workflow to a file"
        path = os.path.join(self.outdir, "tc.txt")
        f = open(path, "w")
        try:
            f.write("""
tr acme-run {
    site local {
        pfn "file://%s/bin/acme-run.sh"
        arch "x86_64"
        os "linux"
        type "STAGEABLE"
        profile pegasus "exitcode.successmsg" "SUCCESSFUL TERMINATION"
        profile globus "hostcount" "%s"
        profile globus "jobtype" "single"
    }
}

tr acme-output {
    site local {
        pfn "file://%s/bin/acme-output.sh"
        arch "x86_64"
        os "linux"
        type "STAGEABLE"
        profile globus "hostcount" "1"
        profile globus "jobtype" "single"
    }
}
""" % (DAXGEN_DIR, self.mppwidth, DAXGEN_DIR))
        finally:
            f.close()

    def generate_dax(self):
        "Generate a workflow (DAX, config files, and replica catalog)"
        dax = ADAG(self.casename)

        last = None

        i = 1
        for stop_n, walltime in zip(self.stop_n, self.walltime):
            stage = Job(name="acme-run")
            if i > 1:
                stage.addArguments("-continue")
            stage.addArguments("-stage %s -stop %s -n %s" % (i, self.stop_option, stop_n))
            stage.addProfile(Profile(namespace="globus", key="maxwalltime", value=walltime))
            dax.addJob(stage)

            if last is not None:
                dax.depends(stage, last)

            output = File("%s.stage%s.tar.gz" % (self.casename, i))

            archive = Job(name="acme-output")
            archive.addArguments("-stage %s" % i)
            archive.uses(output, link=Link.OUTPUT, register=False, transfer=True)
            archive.addProfile(Profile(namespace="globus", key="maxwalltime", value="30"))
            dax.addJob(archive)
            dax.depends(archive, stage)

            # TODO Add data analysis job

            last = archive
            i+=1

        # Write the DAX file
        dax.writeXMLFile(self.daxfile)

    def generate_workflow(self):
        if os.path.isdir(self.outdir):
            raise Exception("Directory exists: %s" % self.outdir)

        # Create the output directory
        self.outdir = os.path.abspath(self.outdir)
        os.makedirs(self.outdir)

        self.generate_dax()
        self.generate_replica_catalog()
        self.generate_transformation_catalog()
        self.generate_env()

def main():
    if len(sys.argv) != 3:
        raise Exception("Usage: %s CONFIGFILE OUTDIR" % sys.argv[0])

    configfile = sys.argv[1]
    outdir = sys.argv[2]

    if not os.path.isfile(configfile):
        raise Exception("No such file: %s" % configfile)

    # Read the config file
    config = ConfigParser()
    config.read(configfile)

    # Generate the workflow in outdir based on the config file
    workflow = ACMEWorkflow(outdir, config)
    workflow.generate_workflow()


if __name__ == '__main__':
    main()

