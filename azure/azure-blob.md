# Set up

## Create a cluster

```bash
./azure-cluster.sh create-csi ciscluster BlobTest 3
```

## Set up storage account

Reference: https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/deploy/example/e2e_usage.md#option2-bring-your-own-storage-account

Create two storage accounts: standard5150 with standard storage type, premium5150 with premium/blob storage type.

```
$ az storage account list | grep name
    "name": "premium5150",
      "name": "Premium_LRS",
    "name": "standard5150",
      "name": "Standard_LRS",
```

Find your storage keys to be used below to create storage classes:
```
kubectl create secret generic azure-secret --from-literal accountname=standard5150 --from-literal accountkey="find in access keys of your storage account" --type=Opaque
kubectl create -f blob/blob-storage-class.yaml

kubectl create secret generic azure-secret-premium --from-literal accountname=premium5150 --from-literal accountkey="find in access keys of your storage account" --type=Opaque
kubectl create -f blob/blob-premium-storage-class.yaml
```

## Install Blob CSI driver

Reference: https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/install-csi-driver-v1.2.0.md

```
# Install Blob
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/v1.2.0/deploy/install-driver.sh | bash -s v1.2.0 --
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
./run-dbench-test.sh -t azure-blob-dbench-default
```

## Test results

FAILED. See FAQ error 2.

```bash
grep -A 5 Summary results/azure-blob-dbench-default-output.txt
```

# Run dbench tests: multiple

## Test steps

```bash
./azure-blob-run-dbench-tests.sh
```

## Test results

FAILED. See FAQ error 2.

```bash
grep -A 5 Summary results/azure-blob-*
```

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f azure-blob.yaml

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
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 34.1415 s, 60.0 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 36.7007 s, 55.8 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 36.9145 s, 55.5 MB/s

root@nginx:/mnt/nfs-file-share# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 48.3467 s, 42.4 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 48.4389 s, 42.3 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 48.2004 s, 42.5 MB/s

root@nginx:/mnt/default# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
real    0m32.678s
user    0m0.647s
sys     0m0.705s

real    0m32.470s
user    0m0.641s
sys     0m0.706s

real    0m31.683s
user    0m0.592s
sys     0m0.720s

root@nginx:/mnt/default# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m18.328s
user    0m0.035s
sys     0m0.303s

real    0m18.795s
user    0m0.032s
sys     0m0.260s

real    0m20.017s
user    0m0.013s
sys     0m0.299s
```

### Test result for storage class "blob-premium"

```bash
root@nginx:/mnt/default# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 34.4051 s, 59.5 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 34.0067 s, 60.2 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 34.3947 s, 59.5 MB/s

root@nginx:/mnt/nfs-file-share# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 47.9459 s, 42.7 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 47.394 s, 43.2 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 47.6749 s, 43.0 MB/s

root@nginx:/mnt/default# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
real    0m25.650s
user    0m0.628s
sys     0m0.702s

real    0m27.151s
user    0m0.573s
sys     0m0.750s

real    0m26.787s
user    0m0.585s
sys     0m0.706s

root@nginx:/mnt/default# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m14.830s
user    0m0.040s
sys     0m0.306s

real    0m15.606s
user    0m0.031s
sys     0m0.304s

real    0m15.562s
user    0m0.026s
sys     0m0.310s
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

## Error: Can't create PVC

Error: The client '1d8d18a4-2ba0-4b6d-8e10-37bbf97842fb' with object id '1d8d18a4-2ba0-4b6d-8e10-37bbf97842fb' does not have authorization to perform action 'Microsoft.Storage/storageAccounts/read' over scope

See the errors from logs: 
```
kubectl logs deploy/csi-blob-controller -c blob -f -n kube-system
kubectl logs daemonset/csi-blob-node -c blob -n kube-system -f
```

The reason is that the client "ciscluster-agentpool" (managed identity or msi)
doesn't have any permission upon storage accounts.

To fix it, open the managed identity in portal, click "Azure role assignment"
and assign it the "Contributor" role for resource group "MC_...".

## Error: dbench test failed

Couldn't figure out why.

```
$ kubectl apply -f azure-blob-dbench-default.yaml
$ kubectl logs pod/dbench-job-wtvlk
Working dir: /data

Testing Read IOPS...
fio: posix_fallocate fails: Not supported
fio: io_u error on file /data/fiotest: Invalid argument: read offset=923754496, buflen=4096
fio: io_u error on file /data/fiotest: Invalid argument: read offset=1736273920, buflen=4096

$ kubectl get events
```