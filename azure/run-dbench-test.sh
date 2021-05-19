#!/bin/bash
# Run one storage test.
#
# Test storage class and capacity as defined in azure-basic-dbench-default.yaml:
#     ./run-dbench-test.sh -t azure-basic-dbench-default
# It does the following:
# 1. Deploy a job to run dbench as sepecified in azure-basic-dbench-default.yaml.
# 2. Store result to results/azure-basic-dbench-default-output.txt.
# 3. Delete the deployment in azure-basic-dbench-default.yaml.
#
# Test storage class "premium" with 100Gi storage capacity:
#     ./run-one-test.sh -scl premium -sca 100Gi
# This will generate yaml file results/premium-100Gi.yaml and output file
# results/premium-100Gi-output.txt.

# Print command
set -x

##########################
# Get input params.
##########################

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-h] [TEST]
Run the specified test and write the result to a txt file.

    -h                      display this help and exit
    -t TEST                 run the specified test, e.g., "sample-10"
    -nfs IP                 internal IP of the NFS server
    -scl STORAGE_CLASS      storage class name, e.g., "default" or "premium"
    -sca STORAGE_CAPACITY   storage capacity, e.g., "10Gi" or "1Ti"
EOF
}

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
test=
nfs_server_internal_ip=
storage_class="default"
storage_capacity="10Gi"

# From: https://mywiki.wooledge.org/BashFAQ/035
while :; do
    case $1 in
        -h)
            show_help
            exit
            ;;
        -nfs)
            if [[ $2 ]]; then
                nfs_server_internal_ip=$2
		echo "NFS server internal IP is ${nfs_server_internal_ip}."
                shift
            else
                die 'ERROR: "-nfs" requires a non-empty option argument.'
            fi
            ;;
        -scl)       # Takes an option argument; ensure it has been specified.
            if [[ $2 ]]; then
                storage_class=$2
		echo ${storage_class}
                shift
            else
                die 'ERROR: "-scl" requires a non-empty option argument.'
            fi
            ;;
        -sca)       # Takes an option argument; ensure it has been specified.
            if [[ $2 ]]; then
                storage_capacity=$2
		echo ${storage_capacity}
                shift
            else
                die 'ERROR: "-sca" requires a non-empty option argument.'
            fi
            ;;
        -t)       # Takes an option argument; ensure it has been specified.
            if [[ $2 ]]; then
                test=$2
                shift
            else
                die 'ERROR: "--test" requires a non-empty option argument.'
            fi
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

# Construct yaml files.
if [[ -z ${test} ]]; then
    # Use default storage class.
    if [[ -z ${nfs_server_internal_ip} ]]; then
        test="${storage_class}-${storage_capacity}"
        yaml_file="results/${test}.yaml"
        echo "Generate & use ${yaml_file}"
        awk -v scl=${storage_class} -v sca=${storage_capacity} '{gsub("STORAGE_CLASS",scl);gsub("STORAGE_CAPACITY",sca);print}' azure-basic-template.yaml > ${yaml_file}
    # Use NFS server.
    else
        test="nfs-${storage_capacity}"
        yaml_file="results/${test}.yaml"
        echo "Generate & use ${yaml_file}"
        awk -v nfs=${nfs_server_internal_ip} -v sca=${storage_capacity} '{gsub("NFS_SERVER_INTERNAL_IP",nfs);gsub("STORAGE_CAPACITY",sca);print}' azure-nsf-template.yaml > ${yaml_file}
    fi
# Use sample yaml files.
else
    yaml_file="${test}.yaml"
    echo "Use ${yaml_file}"
fi
output_file="results/${test}-output.txt"

##########################
# Deploy & run.
##########################
# ========================
kubectl apply -f ${yaml_file}
kubectl wait --for=condition=complete job.batch/dbench-job --timeout=600s

##########################
# Generate output file.
##########################
echo ======================== >> ${output_file}
date >> ${output_file}
echo ======================== >> ${output_file}
cat ${yaml_file} >> ${output_file}
kubectl get all >> ${output_file}
kubectl get pvc >> ${output_file}
pod=$(kubectl get po --no-headers -o custom-columns=":metadata.name")
kubectl describe po ${pod} >> ${output_file}
kubectl logs -f job.batch/dbench-job >> ${output_file}

##########################
# Clean up.
##########################
kubectl delete -f ${yaml_file}
