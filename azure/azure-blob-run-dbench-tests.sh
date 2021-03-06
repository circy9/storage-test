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
STORAGE_CLASS=('blob' 'blob-premium' 'blob' 'blob-premium' 'blob' 'blob-premium')
STORAGE_CAPACITY=('100Gi' '500Gi' '1Ti')

##########################
# Run tests.
##########################
for i in "${STORAGE_CLASS[@]}"; do
    for j in "${STORAGE_CAPACITY[@]}"; do
        ./run-dbench-test.sh -scl ${i} -sca ${j} -tmpl azure-blob-template.yaml
    done
done