ACME-Workflow
=============

Pegasus workflow for ACME climate models.

Consult the [CESM User's Guide](http://www.cesm.ucar.edu/models/cesm1.2/cesm/doc/usersguide/book1.html)
for more information about the climate code used by this workflow.

Steps to Run the Workflow
-------------------------

1. Create/edit the configuration file (e.g. test.cfg)

 a. Set "casename" to match the name of your case.

 b. Set "mppwidth" to the number of cores that your run requires.

 c. Set "stop_n" and "walltime" to create the number of stages you want
    the workflow to have.

2. Create/edit the setup script (e.g. setup-hopper-F1850-T31_g37.sh)

 a. Set the create_newcase parameters

3. Generate the DAX

    $ python daxgen.py test.cfg setup.sh DIRNAME

4. Edit the site catalog, sites.xml:

 a. Update the "shared-scratch" directory entry to have your username

 b. Update the "shared-storage" directory entry

5. Plan the DAX

    $ ./plan.sh DIRNAME

6. Get NERSC grid proxy using:

    $ myproxy-logon -s nerscca.nersc.gov:7512 -t 24 -T -l YOUR_NERSC_USERNAME

7. Follow output of plan.sh to submit workflow

    $ pegasus-run DIRNAME/path/to/submit/dir

8. Monitor the workflow:

    $ pegasus-status -l DIRNAME/path/to/submit/dir

