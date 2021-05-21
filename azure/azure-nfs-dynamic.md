# Create a cluster with nfs storage class

```bash
./azure-cluster.sh create cluster AKSTest
```

Follow nfs-dynamic/README.md to create nfs storage class.

# Run dbench tests

## Test steps

```bash
./run-dbench-test.sh -t azure-nfs-dynamic-dbench-default
./run-dbench-test.sh -t azure-nfs-dynamic-dbench-default
./run-dbench-test.sh -t azure-nfs-dynamic-dbench-default

```

## Test results

```bash
tail results/azure-nfs-dynamic-dbench-default-output.txt
```

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f azure-nfs-dynamic.yaml

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

# 6. Delete the pod.
kubectl delete -f azure-nfs-dynamic.yaml
```

## Test results

```bash

root@nginx:/mnt/nfs# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
command terminated with exit code 137

root@nginx:/mnt/nfs# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    0m17.130s
user    0m0.534s
sys     0m0.808s

real    0m18.653s
user    0m0.570s
sys     0m0.807s

real    0m17.390s
user    0m0.562s
sys     0m0.756s

root@nginx:/mnt/nfs# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m1.259s
user    0m0.030s
sys     0m0.287s

real    0m1.198s
user    0m0.043s
sys     0m0.271s

real    0m1.160s
user    0m0.027s
sys     0m0.273s
```

# Delete the cluster

```bash
./azure-cluster.sh delete cluster AKSTest
```

# FAQ

#####  Error: command terminated with exit code 137

```bash
$ dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
command terminated with exit code 137
```

Root cause: OOM

```bash
kubectl get events
4s          Warning   SystemOOM   node/aks-nodepool1-30186422-vmss000000   System OOM encountered, victim process: nginx, pid: 30596
```

##### What happens if a PVC requests for more than the NFS server capacity (e.g., 100GB)?

The PVC will fail to bind.

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
15s         Warning   ProvisioningFailed      persistentvolumeclaim/nfs-pvc2           failed to provision volume with StorageClass "example-nfs": error validating options for volume: insufficient available space 105072414720 bytes to satisfy claim for 106300440576 bytes
```

##### What happens if N PVCs in total request for more than the NFS server capacity (e.g., 100GB)?

The PVCs (80Gi + 80Gi > 100Gi) will just work.

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   REASON   AGE
pvc-3aa7b468-a71b-423d-ad3a-edb7d113c1a6   80Gi       RWX            Delete           Bound    default/nfs-pvc       example-nfs             6s
pvc-cd7076d8-f717-457c-81a9-6e24a0720d4b   100Gi      RWO            Delete           Bound    default/default-pvc   default                 131m
pvc-cebc7ffa-de2d-4b4f-b246-d9a1e259df4c   80Gi       RWX            Delete           Bound    default/nfs-pvc2      example-nfs             3s

$ kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
default-pvc   Bound    pvc-cd7076d8-f717-457c-81a9-6e24a0720d4b   100Gi      RWO            default        131m
nfs-pvc       Bound    pvc-3aa7b468-a71b-423d-ad3a-edb7d113c1a6   80Gi       RWX            example-nfs    12s
nfs-pvc2      Bound    pvc-cebc7ffa-de2d-4b4f-b246-d9a1e259df4c   80Gi       RWX            example-nfs    9s
```
