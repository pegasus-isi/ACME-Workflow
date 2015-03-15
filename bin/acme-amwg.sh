#!/bin/bash

set -e

function usage () {
    echo "Usage: $0 -case CASENAME -script diag140804.csh"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ "$#" -ne 0 ]; do
    case "$1" in
        -case)
            shift
            CASENAME=$1
            ;;
        -script)
            shift
            SCRIPT=$1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

if [ -z "$CASENAME" ]; then
    usage
    echo "ERROR: Specify CASENAME"
    exit 1
fi

if [ -z "$SCRIPT" ]; then
    usage
    echo "ERROR: Specify SCRIPT"
    exit 1
fi

# Make sure ImageMagick is on the path
if [ -z "$(which convert)" ]; then
    if [ -z "$MAGICK_HOME" ]; then
        echo "ImageMagick not found. Set MAGICK_HOME."
        exit 1
    fi
    export PATH=$PATH:$MAGICK_HOME/bin
fi

# Need to load the modules for the diagnostics code
module load ncl
module load nco

/bin/csh $PWD/$SCRIPT || true

exit 0

