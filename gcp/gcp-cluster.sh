#!/bin/bash
# Create/delete GKE clusters.
#
# Sample command:
#     ./gcp-cluster.sh create mycluster
#     ./gcp-cluster.sh delete mycluster

# Print command
set -x

ACTION=${1:-create}
CLUSTER=${2:-mycluster}

case "${ACTION}" in

'create')
  echo "Create cluster: ${CLUSTER}"
  time gcloud container clusters create ${CLUSTER} --num-nodes=1
  gcloud container clusters get-credentials ${CLUSTER}
  ;;

'delete')
  echo "Delete cluster: ${CLUSTER}"
  time gcloud container clusters delete ${CLUSTER}
  ;;

*)
  exit 1
  ;;

esac