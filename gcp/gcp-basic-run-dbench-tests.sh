#!/bin/bash
# Run storage tests.
#
# Sample command:
#     ./gcp-basic-run-dbench-tests.sh

# Print command
set -x

##########################
# Get input params.
##########################
STORAGE_CLASS=('standard-rwo' 'premium-rwo')
# 500Gi is the max for standard-rwo and premium-rwo in a zone like us-west1-a.
STORAGE_CAPACITY=('10Gi' '100Gi' '500Gi')

##########################
# Run tests.
##########################
for i in "${STORAGE_CLASS[@]}"; do
    for j in "${STORAGE_CAPACITY[@]}"; do
        ./run-dbench-test.sh -scl ${i} -sca ${j}
    done
done
