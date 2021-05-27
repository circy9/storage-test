# Set up

## Create a cluster

```bash
./azure-cluster.sh create-csi ciscluster BlobTest 3
```

## Grant role to managed identity "ciscluster-agentpool"

Open the managed identity in portal, click "Azure role assignment"
and assign it the "Contributor" role for resource group "MC_...".

## Set up storage classes

```
kubectl create -f blob/blob-storage-class.yaml
kubectl create -f blob/blob-premium-storage-class.yaml
```

## Install Blob CSI driver

Reference: https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/install-csi-driver-master.md

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
root@nginx:/mnt/blob# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 34.7148 s, 59.0 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 34.8283 s, 58.8 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 35.5382 s, 57.6 MB/s

root@nginx:/mnt/blob# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 51.4717 s, 39.8 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 50.8809 s, 40.3 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 51.1301 s, 40.1 MB/s

root@nginx:/mnt/blob# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
real    0m36.027s
user    0m0.528s
sys     0m0.854s

real    0m37.750s
user    0m0.455s
sys     0m0.942s

real    0m35.659s
user    0m0.513s
sys     0m0.874s

root@nginx:/mnt/blob# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m24.757s
user    0m0.032s
sys     0m0.275s

real    0m24.591s
user    0m0.017s
sys     0m0.300s

real    0m24.126s
user    0m0.045s
sys     0m0.288s
```

### Test result for storage class "blob-premium"

```bash
root@nginx:/mnt/blob-premium# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 36.9303 s, 55.5 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 36.8585 s, 55.6 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 35.7944 s, 57.2 MB/s

root@nginx:/mnt/blob-premium# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 51.6055 s, 39.7 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 51.9054 s, 39.5 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 51.7696 s, 39.6 MB/s

root@nginx:/mnt/blob-premium# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
real    0m24.076s
user    0m0.524s
sys     0m0.790s

real    0m24.996s
user    0m0.513s
sys     0m0.842s

real    0m24.643s
user    0m0.529s
sys     0m0.799s

root@nginx:/mnt/blob-premium# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m14.589s
user    0m0.043s
sys     0m0.253s

real    0m14.580s
user    0m0.042s
sys     0m0.270s

real    0m14.535s
user    0m0.042s
sys     0m0.230s
```

# Clean up

## Uninstall Blob CSI driver

```
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/deploy/uninstall-driver.sh | bash -s master --
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

Solution: Change FIO_DIRECT to 0 in the corresponding yaml files.

Symptons:

```
$ kubectl apply -f azure-blob-dbench-default.yaml

$ kubectl logs dbench-job-82szp
Working dir: /data

Testing Read IOPS...
fio: posix_fallocate fails: Not supported
fio: io_u error on file /data/fiotest: Invalid argument: read offset=2085343232, buflen=4096
fio: io_u error on file /data/fiotest: Invalid argument: read offset=1534095360, buflen=4096

$ kubectl get events --sort-by='.lastTimestamp'
```

Related: https://unix.stackexchange.com/questions/315833/does-fuse-support-o-direct-directi-o
