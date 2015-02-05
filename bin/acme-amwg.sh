#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 diag140804.csh"
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

# Chmod the templated script for this stage
chmod 755 $1

# Run the script on the service node
./$1 || true

