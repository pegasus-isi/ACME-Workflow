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
tr acme {
    site local {
        pfn "file://%s/bin/acme.sh"
        arch "x86_64"
        os "linux"
        type "STAGEABLE"
    }
}
""" % DAXGEN_DIR)
        finally:
            f.close()

    def generate_workflow(self):
        "Generate a workflow (DAX, config files, and replica catalog)"
        dax = ADAG("refinement")

        stage = Job(name="acme")
        stage.addArguments("-run stage1 -stop days -n 5")
        dax.addJob(stage)

        # Write the DAX file
        dax.writeXMLFile(self.daxfile)

        self.generate_replica_catalog()

        self.generate_transformation_catalog()

def main():
    if len(sys.argv) != 3:
        raise Exception("Usage: %s CONFIGFILE OUTDIR" % sys.argv[0])

    configfile = sys.argv[1]
    outdir = sys.argv[2]

    if not os.path.isfile(configfile):
        raise Exception("No such file: %s" % configfile)

    if os.path.isdir(outdir):
        raise Exception("Directory exists: %s" % outdir)

    # Create the output directory
    outdir = os.path.abspath(outdir)
    os.makedirs(outdir)

    # Read the config file
    config = ConfigParser()
    config.read(configfile)

    # Generate the workflow in outdir based on the config file
    workflow = ACMEWorkflow(outdir, config)
    workflow.generate_workflow()


if __name__ == '__main__':
    main()

