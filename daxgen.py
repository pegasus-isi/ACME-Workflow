#!/usr/bin/env python
import os
import sys
import re
import shutil
import string
from ConfigParser import ConfigParser
from Pegasus.DAX3 import *

DAXGEN_DIR = os.path.dirname(os.path.realpath(__file__))
TEMPLATE_DIR = os.path.join(DAXGEN_DIR, "templates")

def format_template(name, outfile, **kwargs):
    "This fills in the values for the template called 'name' and writes it to 'outfile'"
    templatefile = os.path.join(TEMPLATE_DIR, name)
    template = open(templatefile).read()

    def repl(match):
        key = match.group(1)
        return str(kwargs[key])

    data = re.sub("\{\{([a-z0-9A-Z-._]+)\}\}", repl, template)

    f = open(outfile, "w")
    try:
        f.write(data)
    finally:
        f.close()

class ACMEWorkflow(object):
    def __init__(self, outdir, setup, config):
        "'outdir' is the directory where the workflow is written, and 'config' is a ConfigParser object"
        self.outdir = outdir
        self.setup = setup
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
tr acme-setup {
    site local {
        pfn "file://%s/bin/acme-setup.sh"
        arch "x86_64"
        os "linux"
        type "STAGEABLE"
        profile globus "count" "1"
        profile globus "jobtype" "single"
        profile hints "globusScheduler" "auxiliary"
    }
}

tr acme-run {
    site local {
        pfn "file://%s/bin/acme-run.sh"
        arch "x86_64"
        os "linux"
        type "STAGEABLE"
        profile pegasus "exitcode.successmsg" "SUCCESSFUL TERMINATION"
        profile globus "count" "%s"
        profile globus "jobtype" "single"
    }
}

tr acme-output {
    site local {
        pfn "file://%s/bin/acme-output.sh"
        arch "x86_64"
        os "linux"
        type "STAGEABLE"
        profile globus "count" "1"
        profile globus "jobtype" "single"
    }
}

tr acme-amwg {
    site local {
        pfn "file://%s/bin/acme-amwg.sh"
        arch "x86_64"
        os "linux"
        type "STAGEABLE"
        profile globus "count" "0"
        profile globus "jobtype" "single"
        profile pegasus "exitcode.successmsg" "NORMAL EXIT FROM SCRIPT"
        profile pegasus "exitcode.failuremsg" "CONVERT NOT FOUND"
        profile pegasus "exitcode.failuremsg" "Segmentation fault"
    }
}
""" % (DAXGEN_DIR, DAXGEN_DIR, self.mppwidth, DAXGEN_DIR, DAXGEN_DIR))
        finally:
            f.close()

    def generate_amwg_script(self, stage, first_yr, nyrs):
        "Generate the amwg script with the appropriate config"
        name = "diag140804.stage%s.csh" % stage
        path = os.path.join(self.outdir, name)
        kw = {
            "first_yr": first_yr,
            "nyrs": nyrs,
            "casename": self.casename,
            "stage": stage
        }
        format_template("diag140804.csh", path, **kw)
        self.add_replica(name, path)
        return name

    def generate_dax(self):
        "Generate a workflow (DAX, config files, and replica catalog)"
        dax = ADAG(self.casename)

        if self.stop_option in ["nyear", "nyears"]:
            amwg = True
        else:
            print "WARNING: Diagnostics not added to workflow unles stop option is 'nyears'. Current setting is '%s'" % self.stop_option
            amwg = False

        # Add the setup stage
        setupscript = File(self.setup)
        setup = Job(name="acme-setup")
        setup.addArguments("-case", self.casename, "-setup", setupscript)
        setup.uses(setupscript, link=Link.INPUT, register=False, transfer=True)
        dax.addJob(setup)
        self.add_replica(self.setup, os.path.join(self.outdir, self.setup))

        last = None
        tot_years = 0
        i = 1
        for stop_n, walltime in zip(self.stop_n, self.walltime):
            stage = Job(name="acme-run")
            stage.addArguments("-stage %s -stop %s -n %s" % (i, self.stop_option, stop_n))
            stage.addProfile(Profile(namespace="globus", key="maxwalltime", value=walltime))
            dax.addJob(stage)
            if i == 1:
                dax.depends(stage, setup)
            else:
                stage.addArguments("-continue")

            if last is not None:
                dax.depends(stage, last)

            # This is actually a directory
            output = File("%s-stage%s/" % (self.casename, i))

            archive = Job(name="acme-output")
            archive.addArguments("-stage %s" % i)
            archive.uses(output, link=Link.OUTPUT, register=False, transfer=True)
            archive.addProfile(Profile(namespace="globus", key="maxwalltime", value="30"))
            dax.addJob(archive)
            dax.depends(archive, stage)

            # Figure out how many years we have at this point
            cur_years = int(stop_n)
            tot_years = tot_years + cur_years

            # Add diagnostics job for atmosphere
            if amwg:
                if tot_years <= 1:
                    print "WARNING: First stage does not have enough years for diagnostics"
                else:
                    # The first year doesn't count, do no more than 5 years
                    nyrs = min(tot_years-1, 5)

                    # Years start at 1, not 0
                    first_yr = tot_years - nyrs + 1

                    # Create the amwg script
                    script_name = self.generate_amwg_script(i, first_yr, nyrs)
                    script = File(script_name)

                    # This is actually a directory
                    diagnostics = File("%s-amwg-stage%s/" % (self.casename, i))

                    # Add the job
                    diag = Job(name="acme-amwg")
                    diag.addArguments(script)
                    diag.uses(script, link=Link.INPUT)
                    diag.uses(diagnostics, link=Link.OUTPUT, register=False, transfer=True)
                    diag.addProfile(Profile(namespace="globus", key="maxwalltime", value="30"))
                    dax.addJob(diag)
                    dax.depends(diag, stage)

            last = archive
            i+=1

        # Write the DAX file
        dax.writeXMLFile(self.daxfile)

    def generate_workflow(self):
        self.generate_dax()
        self.generate_replica_catalog()
        self.generate_transformation_catalog()
        self.generate_env()

def main():
    if len(sys.argv) != 4:
        raise Exception("Usage: %s CONFIGFILE SETUP OUTDIR" % sys.argv[0])

    configfile = sys.argv[1]
    setup = sys.argv[2]
    outdir = sys.argv[3]

    if not os.path.isfile(configfile):
        raise Exception("Invalid CONFIGFILE: No such file: %s" % configfile)

    if not os.path.isfile(setup):
        raise Exception("Invalid SETUP script: No such file: %s" % setup)

    outdir = os.path.abspath(outdir)
    if os.path.isdir(outdir):
        raise Exception("Directory exists: %s" % outdir)

    # Read the config file
    config = ConfigParser()
    config.read(configfile)

    # Create the output directory
    os.makedirs(outdir)

    # Save a copy of the config file and setup script
    shutil.copy(configfile, outdir)
    shutil.copy(setup, outdir)

    # Generate the workflow in outdir based on the config file
    workflow = ACMEWorkflow(outdir, os.path.basename(setup), config)
    workflow.generate_workflow()


if __name__ == '__main__':
    main()

