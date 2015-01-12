ACME-Workflow
=============

Pegasus workflow for ACME climate models.

On Hopper
---------
You need to create the case while logged into Hopper.

In the following, assume that these variables are set to the values below:

    ACMEPATH = /global/project/projectdirs/m2187/acme_code/ACME
    CASENAME = F1850.g37.case2
    SCRATCHDIR = /scratch/scratchdirs/juve/
    CASEDIR = $SCRATCHDIR/$CASENAME

Note that the "shared-scratch" directory in your site catalog must match the
value for SCRATCHDIR above. This is because we use CASENAME as the --relative-dir
option for the Pegasus planner so that CASEDIR will become Pegasus' scratch dir.

1. Create the case directory. From $ACMEPATH/scripts run:

    $ ./create_newcase -case $CASEDIR -mach hopper -compset F1850 -res T31_g37 -project m2187

 In this case "m2187" is our Hopper project ID, and "mach" means "machine"
 and should be set to "hopper". The "compset" defines what initial conditions
 you want to use, and "res" specifies the resolution. Possible compsets: F1850, B1850.
 Possible resolutions: ne30_g16, T31_g37.

2. Make any manual changes to the case that are required for your simulation.

3. Setup the case. From $CASEDIR run:

    $ ./cesm_setup

4. Compile the code. This should take about 20 minutes. From $CASEDIR run:

    $ ./$CASENAME.build


On Submit Host
--------------

1. Create/edit the configuration file (e.g. test.cfg)

2. Generate the DAX

    $ python daxgen.py test.cfg $CASENAME

3. Edit the site catalog, sites.xml:

 a. Update the "shared-scratch" directory entry to have your username

 b. Update the "shared-storage" directory entry

4. Plan the DAX

    $ ./plan.sh $CASENAME

5. Get NERSC grid proxy using:

    $ myproxy-logon -s nerscca.nersc.gov:7512 -t 24 -T -l YOUR_NERSC_USERNAME

6. Follow output of plan.sh to submit workflow

    $ pegasus-run $CASENAME/submit/$CASENAME

7. Monitor the workflow:

    $ pegasus-status -l $CASENAME/submit/$CASENAME

