#!/bin/bash

function usage () {
    echo "Usage: $0 -stop STOP_OPTION -n STOP_N -run RUN"
}

if [ "$#" == "0" ]; then
    usage
    exit 1
fi

while [ "$#" -ne 0 ]; do
    case "$1" in
        -case)
            shift
            CASE=$1
            ;;
        -stop)
            shift
            STOP_OPTION=$1
            ;;
        -n)
            shift
            STOP_N=$1
            ;;
        -run)
            shift
            RUN=$1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

echo RUN $RUN
echo STOP_N $STOP_N
echo STOP_OPTION $STOP_OPTION

exit 0

cd $PBS_O_WORKDIR

CASE=$(./xmlquery CASE -valonly -silent)

./xmlchange -file env_run.xml -id RUNDIR -val $PWD/$RUN
./xmlchange -file env_run.xml -id STOP_N -val $STOP_N
./xmlchange -file env_run.xml -id STOP_OPTION -val $STOP_OPTION
./xmlchange -file env_run.xml -id RESUBMIT -val 0
./xmlchange -file env_run.xml -id DOUT_S_ROOT -val \$CASEROOT/archive

exec $CASE.run

