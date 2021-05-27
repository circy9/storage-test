Note: This is Standard LRS by default.

# Set up

## Create a cluster

```bash
./azure-cluster.sh create-csi ciscluster BlobTest 3
```

## Grant role to managed identity "ciscluster-agentpool"

Open the managed identity in portal, click "Azure role assignment"
and assign it the "Contributor" role for resource group "MC_...".

## Set up NFS

https://github.com/kubernetes-sigs/blob-csi-driver/tree/master/deploy/example/nfs#prerequisite

```
az feature register --name AllowNFSV3 --namespace Microsoft.Storage
az feature register --name PremiumHns --namespace Microsoft.Storage
az provider register --namespace Microsoft.Storage
kubectl create -f blob/blob-nfs-storage-class.yaml
```

## Install Blob CSI driver

Reference: https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/install-csi-driver-master.md#install-with-kubectl

```
# Install Blob
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/deploy/install-driver.sh | bash -s master --
# Make sure everything is running
kubectl -n kube-system get po

NAME                                  READY   STATUS    RESTARTS   AGE
csi-blob-controller-56786fd8c-5psl5   4/4     Running   0          34m
csi-blob-controller-56786fd8c-cccz9   4/4     Running   0          34m
csi-blob-node-qnnxn                   3/3     Running   0          34m
csi-blob-node-xgktr                   3/3     Running   0          34m
csi-blob-node-zvmvr                   3/3     Running   0          34m
```

Reference: https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/deploy/example/e2e_usage.md#dynamic-provisioning

# Run dbench tests: single

## Test steps

```bash
./run-dbench-test.sh -t azure-blob-nfs-dbench-default
```

## Test results

```bash
grep -A 5 Summary results/azure-blob-nfs-dbench-default-output.txt
```

# Run dbench tests: multiple

## Test steps

```bash
./azure-blob-nfs-run-dbench-tests.sh
```

## Test results

```bash
grep -A 5 Summary results/azure-blob-nfs-*
```

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f azure-blob-nfs.yaml

# 2. Install wget.
kubectl -it exec pod/nginx -- bash
apt update && apt install wget

# 3. Go to /mnt/blob.
cd /mnt/blob

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

# 6. Repeat 3-5 for /mnt/blob-premium.

# 7. Delete the pod.
kubectl delete -f azure-blob.yaml
```

## Test results

### Test result for storage class "blob"

```bash
root@nginx:/mnt/default# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.0426 s, 157 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 12.708 s, 161 MB/s

root@nginx:/mnt/nfs-file-share# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 70.6451 s, 29.0 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 72.9389 s, 28.1 MB/s

root@nginx:/mnt/default# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
real    5m9.380s
user    0m0.717s
sys     0m1.244s

real    5m12.331s
user    0m0.742s
sys     0m1.330s

real    5m12.982s
user    0m0.727s
sys     0m1.511s

root@nginx:/mnt/default# time ( du wordpress/ | tail -1 && rm -rf wordpress )
real    0m57.310s
user    0m0.030s
sys     0m0.353s

real    1m1.161s
user    0m0.040s
sys     0m0.401s

real    0m56.157s
user    0m0.039s
sys     0m0.401s
```

# Clean up

## Uninstall Blob CSI driver

```
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/v1.2.0/deploy/uninstall-driver.sh | bash -s v1.2.0 --
```

Reference: https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/install-csi-driver-v1.2.0.md

## Delete the cluster

```bash
./azure-cluster.sh delete ciscluster BlobTest
```

# FAQ
