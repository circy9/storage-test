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
STORAGE_CLASS=('default'  'managed-premium' 'azurefile' 'azurefile-premium')
STORAGE_CAPACITY=('10Gi' '100Gi' '500Gi')

##########################
# Run tests.
##########################
for i in "${STORAGE_CLASS[@]}"; do
    for j in "${STORAGE_CAPACITY[@]}"; do
        ./run-dbench-test.sh -scl ${i} -sca ${j}
    done
done
