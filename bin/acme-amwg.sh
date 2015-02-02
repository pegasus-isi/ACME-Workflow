#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 diag140804.csh"
    exit 1
fi

# Need to load the modules for the diagnostics code
module load ncl
module load nco

# Chmod the templated script for this stage
chmod 755 $1

# Run the script on a compute node
aprun -n 1 ./$1

