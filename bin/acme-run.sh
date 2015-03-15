#!/bin/bash -l

set -e

function usage () {
    echo "Usage: $0 [-continue] -case CASENAME -stage N -stop STOP_OPTION -n STOP_N"
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
        -continue)
            CONTINUE_RUN=TRUE
            ;;
        -stage)
            shift
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

echo CASENAME $CASENAME
echo STOP_N $STOP_N
echo STOP_OPTION $STOP_OPTION
echo CONTINUE_RUN $CONTINUE_RUN
echo STAGE $STAGE

if [ -z "$CASENAME" ]; then
    echo "ERROR: Specify -case"
    usage
    exit 1
fi

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

export CASENAME
export CASEROOT=$PWD/$CASENAME

cd $CASENAME

# Make sure that the run directory is correct
./xmlchange -file env_run.xml -id RUNDIR -val $CASEROOT/run

# We never want to resubmit the jobs in the Pegasus workflow
./xmlchange -file env_run.xml -id RESUBMIT -val 0

# Only continue for stage > 1
./xmlchange -file env_run.xml -id CONTINUE_RUN -val $CONTINUE_RUN

# Set the interval
./xmlchange -file env_run.xml -id STOP_OPTION -val $STOP_OPTION
./xmlchange -file env_run.xml -id STOP_N -val $STOP_N

# Disable archiving
./xmlchange -file env_run.xml -id DOUT_S -val FALSE
./xmlchange -file env_run.xml -id DOUT_L_MS -val FALSE

# Disable timing
./xmlchange -file env_run.xml -id CHECK_TIMING -val FALSE
./xmlchange -file env_run.xml -id SAVE_TIMING -val FALSE

# This script often returns non-zero, so we need to mask the failure
# We use exitcode.successmessage to detect failures
/bin/csh ./$CASENAME.run || true

exit 0

