# Set Up

```bash
# Create a resource group.
export location="westus2"
export rg="liqianhcpcachetest"
az group create -l ${location} -n ${rg}

# Create an AKS cluster.
./azure-cluster.sh create cluster ${rg}

# Create a subnet.
export rg="MC_liqianhcpcachetest_cluster_westus2"
export vnet="aks-vnet-62726283"
export subnet="cacheSubnet"
az network vnet create -g ${rg} -n ${vnet} --address-prefix 10.0.0.0/16 \
  --subnet-name ${subnet} --subnet-prefix 10.0.0.0/24
az network vnet subnet update -g ${rg} -n ${subnet} --vnet-name ${vnet} --service-endpoints Microsoft.Storage

# Create a storage account and allow the subnet to access it.
export storage="liqianblob"
az storage account create -g ${rg} -n ${storage} --sku Standard_LRS
az storage account network-rule add -g ${rg} --account-name ${storage} --vnet-name ${vnet} --subnet ${subnet}
# Using portal, assign to role "Storage Account Contributor" and role "Storage Blob Data Contributor" to user "StorageCache Resource Provider"
# Using portal, create a container called "container"

# Create a HPC cache in the subnet.
export sub="8ecadfc9-d1a3-4ea4-b844-0d9f87e4d7c8"
export cache="liqianhpccache2"
az hpc-cache create -g ${rg} -l ${location} --name ${cache} --cache-size-gb "3072" --subnet "/subscriptions/${sub}/resourceGroups/${rg}/providers/Microsoft.Network/virtualNetworks/${vnet}/subnets/${subnet}" --sku-name "Standard_2G"

# Create a storage target.
export storage_target="liqiantarget"
export storage_container="container"
export namespace_path="/blob"
az hpc-cache blob-storage-target add -g ${rg} \
  --cache-name ${cache} --name ${storage_target} \
  --storage-account "/subscriptions/${sub}/resourceGroups/${rg}/providers/Microsoft.Storage/storageAccounts/${storage}" \
  --container-name ${storage_container} --virtual-namespace-path ${namespace_path}
```

# Run dbench tests: single

## Test steps

```bash
./run-dbench-test.sh -t azure-hpc-cache-dbench-default
```

## Test results

```bash
grep -A 5 Summary results/azure-hpc-cache-dbench-default-output.txt
```

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f azure-hpc-cache.yaml

# 2. Install wget.
kubectl -it exec pod/nginx -- bash
apt update && apt install wget

# 3. Go to /mnt/nfs.
cd /mnt/nfs

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
```

## Test results

```bash
root@nginx:/mnt/nfs# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 16.6187 s, 123 MB/s

root@nginx:/mnt/nfs# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 24.5589 s, 83.4 MB/s

root@nginx:/mnt/nfs# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
tar: wordpress/xmlrpc.php: Cannot change ownership to uid 65534, gid 65534: Operation not permitted
tar: wordpress/wp-blog-header.php: Cannot change ownership to uid 65534, gid 65534: Operation not permitted

root@nginx:/mnt/nfs# mount | grep /mnt
10.0.0.4:/blob on /mnt/nfs type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=10.0.0.4,mountvers=3,mountport=4046,mountproto=udp,local_lock=none,addr=10.0.0.4)
```