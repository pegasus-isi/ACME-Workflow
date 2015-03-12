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

$ACMEROOT/scripts/create_newcase -case $CASEROOT -mach hopper -compset F1850 -res T31_g37

cd $CASEROOT

./cesm_setup

./$CASENAME.build

