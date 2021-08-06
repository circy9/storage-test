This doc contains the test steps and results of Rook Ceph storage based
on Azure managed disks (the "default" storage class in AKS).

# Create a cluster with 3 nodes

```bash
./azure-cluster.sh create cluster RookTest 3
```

# Set up rook ceph

Reference: https://rook.io/docs/rook/v1.6/ceph-quickstart.html

## Set up ceph cluster

```bash
$ git clone --single-branch --branch v1.6.8 https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph
kubectl create -f crds.yaml -f common.yaml -f operator.yaml

# Verify operator is running.
$ kubectl -n rook-ceph get pod
NAME                                  READY   STATUS    RESTARTS   AGE
rook-ceph-operator-6459f5dc4b-cm6j4   1/1     Running   0          4m52s

# Change storageClassName from "gp2" (AWS default) to "default".
# Note that you can also use other storage classes as listed here: https://docs.microsoft.com/en-us/azure/aks/concepts-storage#storage-classes
vi cluster-on-pvc.yaml
kubectl create -f cluster-on-pvc.yaml

# Install tools: https://rook.io/docs/rook/v1.6/ceph-toolbox.html
kubectl create -f toolbox.yaml

# Check status. Expect to see mon, mgr and osd under services.
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
ceph status

# Expose the dashboard: https://github.com/rook/rook/blob/master/Documentation/ceph-dashboard.md
kubectl create -f dashboard-loadbalancer.yaml
❯ kubectl get service rook-ceph-mgr-dashboard-loadbalancer -n rook-ceph
NAME                                   TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
rook-ceph-mgr-dashboard-loadbalancer   LoadBalancer   10.0.132.195   13.91.217.119   8443:31277/TCP   9m20s
# Use https://13.91.217.119:8443 to access the dashboard with user name: admin, and password as outputted:
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

## Set up filesystem & storage class

```bash
# Create filesystem: https://rook.io/docs/rook/v1.6/ceph-filesystem.html.
kubectl create -f filesystem.yaml

# Wait for running.
kubectl -n rook-ceph get pod -l app=rook-ceph-mds

# View status. Expect to see mds under services.
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
ceph status

# Create storage class.
kubectl apply -f csi/cephfs/storageclass.yaml 
```

# Run dbench tests: single

## Test steps

```bash
./run-dbench-test.sh -t azure-rook-ceph-dbench-default
```

## Test results

```bash
tail results/azure-rook-ceph-dbench-default-output.txt
```

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f azure-rook-ceph.yaml

# 2. Install wget.
kubectl -it exec pod/nginx -- bash
apt update && apt install wget

# 3. Go to /mnt/rook-cephfs.
cd /mnt/rook-cephfs

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

# 6. Delete the pod.
kubectl delete -f azure-nfs-dynamic.yaml
```

## Test results

```bash
root@nginx:/mnt/rook-cephfs# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
command terminated with exit code 137

root@nginx:/mnt/rook-cephfs# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    0m7.604s
user    0m0.496s
sys     0m0.352s

real    0m11.171s
user    0m0.470s
sys     0m0.326s

real    0m4.678s
user    0m0.459s
sys     0m0.322s

real    0m9.269s
user    0m0.472s
sys     0m0.334s

real    0m6.120s
user    0m0.507s
sys     0m0.337s

root@nginx:/mnt/rook-cephfs# time ( du wordpress/ | tail -1 && rm -rf wordpress )
52034   wordpress/

real    0m4.449s
user    0m0.024s
sys     0m0.101s

real    0m3.874s
user    0m0.031s
sys     0m0.099s

real    0m5.878s
user    0m0.018s
sys     0m0.113s

real    0m7.401s
user    0m0.036s
sys     0m0.095s

real    0m5.468s
user    0m0.022s
sys     0m0.108s
```

# FAQ

## Resize an existing PV? Yes
```
# Create a pod.
# Change
#   storage: 10Gi
# to
#   storage: 10Mi
vi azure-rook-ceph.yaml
kubectl apply -f azure-rook-ceph.yaml

# Download a 10MB file.
kubectl -it exec pod/nginx -- bash
$ apt update && apt install wget
$ cd /mnt/rook-cephfs
$ df -h .
$ wget https://github.com/yourkin/fileupload-fastapi/raw/a85a697cab2f887780b3278059a0dd52847d80f3/tests/data/test-10mb.bin
$ df -h .
$ cp test-10mb.bin test-10mb.bin2
cp: error writing 'test-10mb.bin2': Disk quota exceeded
$ exit

# Update the pod: change
#   storage: 10Mi
# to
#   storage: 20Mi
vi azure-rook-ceph.yaml
kubectl apply -f azure-rook-ceph.yaml

# Try copy again.
kubectl -it exec pod/nginx -- bash
root@nginx:/mnt/rook-cephfs# cp test-10mb.bin test-10mb.bin2
root@nginx:/mnt/rook-cephfs# df -h .
```

## Scaling out storage? Yes

```
# Check BEFORE status.
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
ceph status

# Change storageClassDeviceSets count from 3 to 4.
vi cluster-on-pvc.yaml
kubectl apply -f cluster-on-pvc.yaml

# Check AFTER status.
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
ceph status | egrep "osd|usage"
    osd: 4 osds: 4 up (since 91s), 4 in (since 91s)
    usage:   4.1 GiB used, 36 GiB / 40 GiB avail
```

## Scale up storage? No for Azure disk

```
# Change storageClassDeviceSets.volumeClaimTemplates.spec.resources.requests.storage from 10Gi to 15Gi.
vi cluster-on-pvc.yaml
kubectl apply -f cluster-on-pvc.yaml

$ kubectl get events -n rook-ceph --sort-by=".lastTimestamp"
31s         Warning   VolumeResizeFailed       persistentvolumeclaim/set1-data-2hs44p                    resize volume "pvc-4fa1fd41-67d2-4daf-a646-edc10075cb02" by resizer "disk.csi.azure.com" failed: rpc error: code = Internal desc = failed to resize disk(/subscriptions/8ecadfc9-d1a3-4ea4-b844-0d9f87e4d7c8/resourceGroups/mc_rooktest_cluster_westus/providers/Microsoft.Compute/disks/pvc-4fa1fd41-67d2-4daf-a646-edc10075cb02) with error(azureDisk - disk resize is only supported on Unattached disk, current disk state: Attached, already attached to /subscriptions/8ecadfc9-d1a3-4ea4-b844-0d9f87e4d7c8/resourceGroups/MC_RookTest_cluster_westus/providers/Microsoft.Compute/virtualMachineScaleSets/aks-nodepool1-39458517-vmss/virtualMachines/aks-nodepool1-39458517-vmss_1)
```

# Failures

## PV stuck in released state
After deleting PVC, the corresponding PV stuck in released state.

```

$ kubectl apply -f azure-rook-ceph.yaml

$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                        STORAGECLASS   REASON   AGE
pvc-4c0a8172-d458-4b10-8a26-08da2400ca33   20Gi       RWX            Delete           Released   default/rook-cephfs-pvc      rook-cephfs             16h

$ kubectl describe pv pvc-4c0a8172-d458-4b10-8a26-08da2400ca33
...
Events:
  Type     Reason              Age                  From                                                                                                              Message
  ----     ------              ----                 ----                                                                                                              -------
  Warning  VolumeFailedDelete  10s (x267 over 16h)  rook-ceph.cephfs.csi.ceph.com_csi-cephfsplugin-provisioner-775dcbbc86-85lgn_3cecc7f5-bc58-4fbd-9570-5997aa7b1695  rpc error: code = Aborted desc = an operation with the given Volume ID 0001-0009-rook-ceph-0000000000000001-e7658af0-f581-11eb-9387-f2981ea12351 already exists

```

Deleted manually.

```
❯ kubectl delete pv pvc-4c0a8172-d458-4b10-8a26-08da2400ca33
```

# Clean Up

```bash
./azure-cluster.sh delete cluster RookTest
```
