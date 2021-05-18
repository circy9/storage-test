#!/bin/bash

# Print command
set -x

ACTION=${1:-create}
CLUSTER=${2:-cluster}

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