#!/bin/bash
# This is an example ACME setup script. The workflow runs this script with
# several environment variables:
#
#     ACMEROOT: This is the path to the ACME/CESM source code
#     CASENAME: The name of the case
#     CASEROOT: This is the path to the case directory
#
# This script should run create_newcase, cesm_setup and $CASENAME.build.
#
set -e

echo "ACMEROOT " $ACMEROOT
echo 'CASEROOT ' $CASEROOT
echo "MACH " $MACH
echo "COMPSET " $COMPSET
echo "RES " $RES
echo "PROJECT " $PROJECT
echo "COMPILER " $COMPILER
echo "AENV " $AENV

$ACMEROOT/cime/scripts/create_newcase -case $CASEROOT -mach $MACH -compset $COMPSET -res $RES -project $PROJECT -compiler $COMPILER

cd $CASEROOT

# Set the directory for executables
./xmlchange -file env_build.xml -id EXEROOT -val $CASEROOT/bld

# Set the run directory
./xmlchange -file env_run.xml -id RUNDIR -val $CASEROOT/run

./cesm_setup

./$CASENAME.build || true

