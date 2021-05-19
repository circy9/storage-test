#!/bin/bash
# Create or delete a cluster.

# Print command
set -x

LATEST_VERSION=$(az aks get-versions -l eastus -o json --query "orchestrators[-1].orchestratorVersion" -o tsv)
echo "${LATEST_VERSION}"

#########################################
# Create a cluster.
# Globals:
#   LATEST_VERSION: latest Kubernete version
# Arguments:
#   name: name of the cluster
#   resource_group: resource group of the cluster
#########################################
function create_cluster {
  local name=$1
  local resource_group=$2
  echo "Creating cluster ${name} in resource group ${resource_group} ..."
  time az aks create -n ${name} -g ${resource_group} \
    -k ${LATEST_VERSION} \
    --no-ssh-key \
    --enable-managed-identity \
    --node-count 1
  echo "Created ${name} in ${resource_group} ..."
}

#########################################
# Create a CSI cluster.
# Globals:
#   LATEST_VERSION: latest Kubernete version
# Arguments:
#   name: name of the cluster
#   resource_group: resource group of the cluster
#########################################
function create_csi_cluster {
  local name=$1
  local resource_group=$2
  echo "Creating cluster ${name} in resource group ${resource_group} ..."
  time az aks create -n ${name} -g ${resource_group} \
    -k ${LATEST_VERSION} \
    --no-ssh-key \
    --enable-managed-identity \
    --aks-custom-headers EnableAzureDiskFileCSIDriver=true \
    --node-count 1
  echo "Created ${name} in ${resource_group} ..."
}


#########################################
# Delete a AKS cluster.
# Globals:
#   None
# Arguments:
#   name: name of the cluster
#   resource_group: resource group of the cluster
#########################################
function delete_cluster {
  az aks list -o table
  local name=$1
  local resource_group=$2
  echo "Deleting cluster $1 in resource group $2 ..."
  time az aks delete -n $name -g $resource_group -y
  echo "Deleted cluster $1 in resource group $2"
}

#########################################
# Create a cluster, run tests, and delete it.
# Globals:
#   None
# Arguments:
#   name: name of the cluster
#   resource_group: resource group of the cluster
#########################################
function main() {
  local action=${1:-create}
  local name=${2:-mycluster}
  local resource_group=${3:-AKSTest}

  case "${action}" in

    'create')
      # Create a cluster.
      az aks list -o table
      create_cluster "${name}" "${resource_group}"
      az aks list -o table
      # Connect to a cluster.
      az aks get-credentials -n "${name}" -g "${resource_group}"
      ;;
      
    'create-csi')
      # Create a cluster.
      az aks list -o table
      create_csi_cluster "${name}" "${resource_group}"
      az aks list -o table
      # Connect to a cluster.
      az aks get-credentials -n "${name}" -g "${resource_group}"
      ;;
      
    'delete')
      # Delete the cluster.
      delete_cluster "${name}" "${resource_group}"
      ;;

    *)
      exit 1
      ;;

  esac
}

main "$@"
