#!/bin/bash -l
# This script creates a new case, runs cesm_setup, and builds the code
set -e

if [ -z "$ACMEROOT" ]; then
    echo "ERROR: Set the ACMEROOT environment variable in sites.xml"
    exit 1
fi
if ! [ -d "$ACMEROOT" ]; then
    echo "ERROR: ACMEROOT does not point to a valid path"
    exit 1
fi


function usage () {
    echo "Usage: $0 -case CASENAME -setup SETUP_SCRIPT"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

CONTINUE_RUN=FALSE
while [ "$#" -ne 0 ]; do
    case "$1" in
        -case)
            shift
            CASENAME=$1
            ;;
        -setup)
            shift
            SETUP_SCRIPT=$1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

if [ -z "$CASENAME" ]; then
    echo "ERROR: Specify -case"
    exit 1
fi

if [ -z "$SETUP_SCRIPT" ]; then
    echo "ERROR: Sepcify -setup"
    exit 1
fi

SCRATCHDIR=$PWD
CASEROOT=$SCRATCHDIR/$CASENAME

echo "CASENAME is $CASENAME"
echo "Setting CASEROOT to $CASEROOT"
echo "Setup script is $SETUP_SCRIPT"

# Clean up after any previous failed run
if [ -d "$CASEROOT" ]; then
    echo "WARNING: CASEROOT already exists: $CASEROOT"
    echo "Removing existing CASEROOT"
    rm -rf $CASEROOT
fi

# Mark the setup script as executable
chmod 755 $SETUP_SCRIPT

export CASENAME
export CASEROOT
export ACMEROOT

# Run the setup script
./$SETUP_SCRIPT || true

exit 0

