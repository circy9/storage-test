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
STORAGE_CLASS=('standard'  'standard-rwo' 'premium-rwo')
STORAGE_CAPACITY=('10Gi' '100Gi' '1Ti')

##########################
# Run tests.
##########################
for i in "${STORAGE_CLASS[@]}"; do
    for j in "${STORAGE_CAPACITY[@]}"; do
        ./run-one-test.sh -scl ${i} -sca ${j}
    done
done
