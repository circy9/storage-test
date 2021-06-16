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
STORAGE_CLASS=('default'  'managed-premium' 'azurefile')
STORAGE_CAPACITY=('10Gi' '100Gi' '500Gi')

##########################
# Run tests.
##########################
for i in "${STORAGE_CLASS[@]}"; do
    for j in "${STORAGE_CAPACITY[@]}"; do
        ./run-dbench-test.sh -scl ${i} -sca ${j}
    done
done

./run-dbench-test.sh -scl 'disk-no-cache' -sca '100Gi'
./run-dbench-test.sh -scl 'azurefile' -sca '1Ti'
./run-dbench-test.sh -scl 'azurefile-premium' -sca '100Gi'
./run-dbench-test.sh -scl 'azurefile-premium' -sca '500Gi'
./run-dbench-test.sh -scl 'azurefile-premium' -sca '1Ti'