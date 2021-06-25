# Create GKE cluster & filestore instances
```bash
./gcp-cluster.sh create cluster
./gcp-filestore.sh create myfilestore
```

# dbench tests: single

## Test steps
```bash

# 0. Update gcp-filestore-dench-hdd.yaml to set spec.nfs.server with IP_ADDRESS
as listed below. For example, "server: 10.239.6.82".

$ gcloud beta filestore instances list
INSTANCE_NAME  ZONE        TIER       CAPACITY_GB  FILE_SHARE_NAME  IP_ADDRESS   STATE  CREATE_TIME
filestore-hdd  us-west1-a  BASIC_HDD  1024         data             10.239.6.82  READY  2021-05-18T17:12:49

# 1. Run run
./run-dbench-test.sh -t gcp-filestore-dbench-hdd
```

Note that we didn't run test SSD as SSD quota is zero for free trial.

## Test results

```bash
tail results/gcp-filestore-dbench-hdd-output.txt
```

# Manual tests

## Test steps

```bash
# 0. Update gcp-filestore-basic.yaml to replace 10.0.0.1 with IP_ADDRESS
as listed below (e.g., 10.239.6.82).

$ gcloud beta filestore instances list
INSTANCE_NAME  ZONE        TIER       CAPACITY_GB  FILE_SHARE_NAME  IP_ADDRESS   STATE  CREATE_TIME
filestore-hdd  us-west1-a  BASIC_HDD  1024         data             10.239.6.82  READY  2021-05-18T17:12:49

# 1. Create a pod.
kubectl apply -f gcp-filestore-basic.yaml

# 2. Install wget.
kubectl -it exec pod/nginx -- bash
apt update && apt install wget

# 3. Go to /mnt/filestore-hdd.
cd /mnt/filestore-hdd

# 4. Write 2GB to file1, copy to file2 and delete both files.
dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
dd if=file1 of=file2 bs=8k count=250000 && sync 
time ( ls -l && rm -f file1 file2 )

# 5. Download and unzip files.
time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
time ( du wordpress/ | tail -1 && rm -rf wordpress )

# 6. Repeat 3-5 for /mnt/filestore-ssd.

# 7. Delete the pod.
kubectl delete -f gcp-filestore-basic.yaml
```

## Test results

### hdd (1Ti)

```bash
root@nginx:/mnt/filestore-hdd# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 15.2306 s, 134 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.2643 s, 154 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 12.8926 s, 159 MB/s

root@nginx:/mnt/filestore-hdd# dd if=file1 of=file2 bs=8k count=250000 && sync 
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.7355 s, 86.3 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.3254 s, 87.8 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 24.0814 s, 85.0 MB/s

root@nginx:/mnt/filestore-hdd# time ( ls -l && rm -f file1 file2 )
total 4000024
-rw-r--r-- 1 root root 2048000000 May 18 17:30 file1
-rw-r--r-- 1 root root 2048000000 May 18 17:31 file2
drwx------ 2 root root      16384 May 18 17:14 lost+found

real    0m1.038s
user    0m0.000s
sys     0m0.079s

root@nginx:/mnt/filestore-hdd# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    0m40.970s
user    0m0.704s
sys     0m1.214s

real    0m28.858s
user    0m0.645s
sys     0m0.981s

real    0m27.927s
user    0m0.607s
sys     0m1.000s

real    0m28.667s
user    0m0.640s
sys     0m1.019s

root@nginx:/mnt/filestore-hdd# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m9.495s
user    0m0.041s
sys     0m0.284s

real    0m6.504s
user    0m0.028s
sys     0m0.225s

real    0m6.568s
user    0m0.022s
sys     0m0.263s

real    0m6.549s
user    0m0.038s
sys     0m0.243s
```

# Delete GKE cluster & filestore instances
```bash
./gcp-filestore.sh delete myfilestore
./gcp-cluster.sh delete cluster
```

# FAQ

Q: Mount failed. What should I do?
A: It worked after recreating the cluster.
