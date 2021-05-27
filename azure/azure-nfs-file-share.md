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

## Create storage account

Reference: https://docs.microsoft.com/en-us/azure/storage/files/storage-files-how-to-create-nfs-shares

Create a storage account via https://portal.azure.com/ as follows.

In the "Basics" tab, select the existing resource group of your cluster, e.g.,
"MC_NFSTest_cluster_westus", for "Resource group",
select the custer region for "Region",
select "Premium" for "Performance",
select "File shares" for "Premium account type",
and select "LRS" for "Redundancy".

In the "Advanced" tab, uncheck "Enable secure transfer".

In the "Networking" tab, select "Public endpoint (selected networks)" for "Connectivity method",
select the existing virtual network of your cluster, e.g., "aks-vnet-12345678",
for "Virtual network",
select the existing subnet of your cluster, e.g., "aks-subnet", for "Subnets".

Skip other tabs and click "Create".

Waiting for the deployment to finish.

# Create storage class

Change the file to use your storage account and its corresponding resource
group: nfs-file-share/nfs-storage-class.yaml.

```
vi nfs-file-share/nfs-storage-class.yaml
kubectl apply -f nfs-file-share/nfs-storage-class.yaml
```

# Run dbench tests: single

## Test steps

```bash
./run-dbench-test.sh -t azure-nfs-file-share-dbench-default
```

## Test results

```bash
grep -A 5 Summary results/azure-nfs-file-share-dbench-default-output.txt
```

# Run dbench tests: multiple

## Test steps

```bash
./azure-nfs-file-share-run-dbench-tests.sh
```

## Test results

```bash
grep -A 5 Summary results/azure-csi-nfs*
```

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f azure-nfs-file-share.yaml

# 2. Install wget.
kubectl -it exec pod/nginx -- bash
apt update && apt install wget

# 3. Go to /mnt/default.
cd /mnt/default

# 4. Write 2GB to file1, copy to file2 and delete both files.
dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
dd if=file1 of=file2 bs=8k count=250000 && sync 
time ( ls -l && rm -f file1 file2 )

# 5. Download and unzip files.
time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
time ( du wordpress/ | tail -1 && rm -rf wordpress )

Here are the sizes of the file before and after unzip:
16M     latest.tar.gz
56M     wordpress
52034   wordpress/

# 6. Repeat 3-5 for /mnt/managed-premium, /mnt/azurefile and /mnt/azurefile-premium.

# 7. Delete the pod.
kubectl delete -f azure-basic.yaml
```

## Test results

```bash
root@nginx:/mnt/default# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 12.7421 s, 161 MB/s

root@nginx:/mnt/nfs-file-share# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 36.3007 s, 56.4 MB/s

root@nginx:/mnt/default# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
real    1m27.944s
user    0m0.531s
sys     0m1.652s

real    1m27.755s
user    0m0.517s
sys     0m1.676s

real    1m29.199s
user    0m0.549s
sys     0m1.653s

root@nginx:/mnt/default# time ( du wordpress/ | tail -1 && rm -rf wordpress )
real    0m14.903s
user    0m0.030s
sys     0m0.409s

real    0m15.065s
user    0m0.034s
sys     0m0.382s

real    0m15.073s
user    0m0.021s
sys     0m0.428s
```

# Delete the cluster

```bash
./azure-cluster.sh delete ciscluster NFSTest
```

# FAQ
