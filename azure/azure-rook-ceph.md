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
$ git clone --single-branch --branch v1.6.3 https://github.com/rook/rook.git
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

# Delete the cluster

```bash
./azure-cluster.sh delete cluster RookTest
```
