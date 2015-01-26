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

if ! [ -z "$PBS_O_WORKDIR" ]; then
    cd $PBS_O_WORKDIR
fi

CASE=$(./xmlquery CASE -valonly -silent)
RUNDIR=$(./xmlquery RUNDIR -valonly -silent)
RUNDIR=$(cd $RUNDIR && pwd)

tar -czv -f ${CASE}.stage${STAGE}.tar.gz -C $RUNDIR ${CASE}.*

