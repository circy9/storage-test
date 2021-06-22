# Create a cluster

```bash
./azure-cluster.sh create-csi ciscluster NFSTest
```

# Enable NFS file share

## Register for the feature
```bash
# Reference: https://docs.microsoft.com/en-us/azure/aks/azure-files-csi
az feature register --namespace "Microsoft.ContainerService" --name "EnableAzureDiskFileCSIDriver"
az feature list -o table --query "[?contains(name, 'EnableAzureDiskFileCSIDriver')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService

# Install the aks-preview extension
az extension add --name aks-preview

# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview

az feature register --namespace "Microsoft.Storage" --name "AllowNfsFileShares"
az feature list -o table --query "[?contains(name, 'AllowNfsFileShares')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.Storage
```

## Create storage class

Reference: https://docs.microsoft.com/en-us/azure/aks/azure-files-csi#nfs-file-shares

```
kubectl apply -f nfs-file-share/nfs-storage-class-new.yaml
```

# Run dbench tests: multiple

## Test steps

```bash
./run-dbench-test.sh -scl azurefile-csi-nfs -sca 100Gi
```

## Test results

```bash
grep -A 5 Summary results/azure-csi-nfs*
```

# Delete the cluster

```bash
./azure-cluster.sh delete ciscluster NFSTest
```
