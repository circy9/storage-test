#!/bin/bash

# Print command
set -x

ACTION=${1:-create}
FILESTORE=${2:-myfilestore}
FILESTORE_HDD="${FILESTORE}-hdd"
FILESTORE_SSD="${FILESTORE}-ssd"
ZONE=${3:-us-west1-a}

case "${ACTION}" in

'create')
  
  echo "Create filestore: ${FILESTORE_HDD}"
  gcloud beta filestore instances create ${FILESTORE_HDD} \
    --zone=${ZONE} \
    --tier=BASIC_HDD \
    --network=name="default" \
    --file-share=name="hdd",capacity=1TiB
  echo "Create filestore: ${FILESTORE_SSD}"
  gcloud beta filestore instances create ${FILESTORE_SSD} \
    --zone=${ZONE} \
    --tier=BASIC_SSD \
    --network=name="default" \
    --file-share=name="ssd",capacity=2560GB
  gcloud beta filestore instances list
  ;;

'delete')
  echo "Delete cluster: ${CLUSTER}"
  gcloud beta filestore instances delete --zone=${ZONE} ${FILESTORE_HDD}
  gcloud beta filestore instances delete --zone=${ZONE} ${FILESTORE_SSD}
  ;;

*)
  exit 1
  ;;

esac