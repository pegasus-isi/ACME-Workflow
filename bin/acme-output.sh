#!/bin/bash -l

set -e

function usage () {
    echo "Usage: $0 -case CASENAME -stage N"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ $# -ne 0 ]; do
    case "$1" in
        -case)
            shift
            CASENAME=$1
            ;;
        -stage)
            shift
            STAGE=$1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

if [ -z "$CASENAME" ]; then
    echo "ERROR: Specify -casename"
    usage
    exit 1
fi

if [ -z "$STAGE" ]; then
    echo "ERROR: Specify -stage"
    usage
    exit 1
fi

CASEROOT=$PWD/$CASENAME

# Get the workflow scratch directory
DIR=$(pwd)

# Make the stage output dir
STAGEDIR=$DIR/${CASENAME}-stage${STAGE}
mkdir $STAGEDIR

# Get the full path to the run directory
RUNDIR=$(cd $CASEROOT && ./xmlquery RUNDIR -valonly -silent)
RUNDIR=$(cd $RUNDIR && pwd)

# Touch this file here so that it will always exist, even if it is empty
# for the first stage
touch outputs_to_ignore

# For each of the new files
for f in $(ls ${RUNDIR}/${CASENAME}.* ${RUNDIR}/*.log.*.gz ${RUNDIR}/rpointer.* | grep -v -f outputs_to_ignore); do
    # Symlink it to the output dir
    ln -s $f ${STAGEDIR}/$(basename $f)
done

# Update the ignore file to ignore outputs from the current stage
ls ${RUNDIR}/${CASENAME}.* ${RUNDIR}/*.log.* > outputs_to_ignore

