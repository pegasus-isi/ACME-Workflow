#!/bin/bash -l

set -e

function usage () {
    echo "Usage: $0 -stage N"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ $# -ne 0 ]; do
    case "$1" in
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

if [ -z "$STAGE" ]; then
    echo "ERROR: Specify -stage"
    usage
    exit 1
fi

# Get the case name
CASE=$(./xmlquery CASE -valonly -silent)

# Get the full path to the run directory
RUNDIR=$(./xmlquery RUNDIR -valonly -silent)
RUNDIR=$(cd $RUNDIR && pwd)

# Get the workflow scratch directory
DIR=$(pwd)

# Make the stage output dir
STAGEDIR=$DIR/${CASE}-stage${STAGE}
mkdir $STAGEDIR

# Touch this file here so that it will always exist, even if it is empty
# for the first stage
touch outputs_to_ignore

# For each of the new files
for f in $(ls ${RUNDIR}/${CASE}.* ${RUNDIR}/*.log.*.gz ${RUNDIR}/rpointer.* | grep -v -f outputs_to_ignore); do
    # Symlink it to the output dir
    ln -s $f ${STAGEDIR}/$(basename $f)
done

# Update the ignore file to ignore outputs from the current stage
ls ${RUNDIR}/${CASE}.* ${RUNDIR}/*.log.* > outputs_to_ignore

