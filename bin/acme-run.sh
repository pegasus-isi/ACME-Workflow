#!/bin/bash

set -e

function usage () {
    echo "Usage: $0 [-continue] -stage N -stop STOP_OPTION -n STOP_N -run RUN"
}

if [ "$#" == "0" ]; then
    usage
    exit 1
fi

CONTINUE_RUN=FALSE
while [ "$#" -ne 0 ]; do
    case "$1" in
        -continue)
            CONTINUE_RUN=TRUE
            ;;
        -stage)
            STAGE=$1
            ;;
        -stop)
            shift
            STOP_OPTION=$1
            ;;
        -n)
            shift
            STOP_N=$1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

echo STOP_N $STOP_N
echo STOP_OPTION $STOP_OPTION
echo CONTINUE_RUN $CONTINUE_RUN
echo STAGE $STAGE

if [ -z "$STAGE" ]; then
    echo "ERROR: Specify -stage"
    usage
    exit 1
fi

if [ -z "$STOP_N" ]; then
    echo "ERROR: Specify -n"
    usage
    exit 1
fi

if [ -z "$STOP_OPTION" ]; then
    echo "ERROR: Specify -stop"
    usage
    exit 1
fi

if ! [ -z "$PBS_O_WORKDIR" ]; then
    cd $PBS_O_WORKDIR
fi

# We never want to resubmit the jobs in the Pegasus workflow
./xmlchange -file env_run.xml -id RESUBMIT -val 0

# Only continue for stage > 1
./xmlchange -file env_run.xml -id CONTINUE_RUN -val $CONTINUE_RUN

# Set the interval
./xmlchange -file env_run.xml -id STOP_OPTION -val $STOP_OPTION
./xmlchange -file env_run.xml -id STOP_N -val $STOP_N

# We might need to change these
#./xmlchange -file env_run.xml -id RUNDIR -val $PWD/$RUN
#./xmlchange -file env_run.xml -id DOUT_S_ROOT -val \$CASEROOT/archive

# Get the case name and invoke the script
CASE=$(./xmlquery CASE -valonly -silent)
exec $CASE.run

