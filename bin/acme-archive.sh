#!/bin/bash

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

# The tar works better from the run dir
cd $RUNDIR

# Touch this file here so that it will always exist, even if it is empty
# for the first stage
touch outputs_to_ignore

# Tar up all the output files, but ignore outputs from previous stages
tar -czv -f $DIR/${CASE}.stage${STAGE}.tar.gz -X outputs_to_ignore ${CASE}.*

# Update the ignore file to ignore outputs from the current stage
ls ${CASE}.* > outputs_to_ignore

