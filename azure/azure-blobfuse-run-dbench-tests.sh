#!/bin/bash
# Run storage tests.
#
# Sample command:
#     ./run-tests.sh

# Print command
set -x

##########################
# Get input params.
##########################
STORAGE_CLASS=('blob' 'blob' 'blob' 'blob-premium' 'blob-premium')
STORAGE_CAPACITY=('100Gi' '500Gi' '1Ti')

##########################
# Run tests.
##########################
for i in "${STORAGE_CLASS[@]}"; do
    for j in "${STORAGE_CAPACITY[@]}"; do
        ./run-dbench-test.sh -scl ${i} -sca ${j}
    done
done