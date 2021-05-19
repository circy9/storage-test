# Create a cluster

```bash
./gcp-cluster.sh create mycluster
```

# Run dbench tests: single

## Test steps

```bash
./run-dbench-test.sh -t gcp-basic-dbench-standard
```

## Test results

See results/gcp-basic-dbench-standard-output.txt.

# Run dbench tests: multiple

## Test steps

```bash
./gcp-basic-run-dbench-tests.sh
```

## Test results

See results/{storage-class}-{storage-capacity}-output.txt.

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f gcp-basic.yaml

# 2. Install wget.
kubectl -it exec pod/nginx -- bash
apt update && apt install wget

# 3. Go to /mnt/standard.
cd /mnt/standard

# 4. Write 2GB to file1, copy to file2 and delete both files.
dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
dd if=file1 of=file2 bs=8k count=250000 && sync 
time ( ls -l && rm -f file1 file2 )

# 5. Download and unzip files.
time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
time ( du wordpress/ | tail -1 && rm -rf wordpress )

# 6. Repeat 3-5 for /mnt/standard-rwo and /mnt/premium-rwo.

# 7. Delete the pod.
kubectl delete -f gcp-basic.yaml
```

## Test results

### Storage Class "standard"

```bash
root@nginx:/mnt/standard# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 11.0154 s, 186 MB/s

root@nginx:/mnt/standard# dd if=file1 of=file2 bs=8k count=250000 && sync 
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 17.2597 s, 119 MB/s

root@nginx:/mnt/standard# time ( ls -l && rm -f file1 file2 )
total 4000024
-rw-r--r-- 1 root root 2048000000 May 18 00:00 file1
-rw-r--r-- 1 root root 2048000000 May 18 00:01 file2
drwx------ 2 root root      16384 May 17 23:40 lost+found

real    0m0.355s
user    0m0.001s
sys     0m0.088s

root@nginx:/mnt/standard# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    0m3.831s
user    0m0.511s
sys     0m0.305s

real    0m3.845s
user    0m0.519s
sys     0m0.344s

real    0m3.855s
user    0m0.537s
sys     0m0.353s

root@nginx:/mnt/standard# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m0.316s
user    0m0.007s
sys     0m0.078s
```

### Storage Class "standard-rwo"

```bash
root@nginx:/mnt/standard-rwo# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 11.1838 s, 183 MB/s

root@nginx:/mnt/standard-rwo# dd if=file1 of=file2 bs=8k count=250000 && sync 
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 85.6094 s, 23.9 MB/s

root@nginx:/mnt/standard-rwo# time ( ls -l && rm -f file1 file2 )
total 4000028
-rw-r--r-- 1 root   root    2048000000 May 18 00:03 file1
-rw-r--r-- 1 root   root    2048000000 May 18 00:04 file2

real    0m0.129s
user    0m0.001s
sys     0m0.046s

root@nginx:/mnt/standard-rwo# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    0m4.811s
user    0m0.520s
sys     0m0.432s

real    0m3.720s
user    0m0.499s
sys     0m0.347s

real    0m3.850s
user    0m0.532s
sys     0m0.320s

root@nginx:/mnt/standard-rwo# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m0.285s
user    0m0.006s
sys     0m0.070s
```

### Storage Class "premium-rwo"

```bash
root@nginx:/mnt/premium-rwo# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 11.748 s, 174 MB/s

root@nginx:/mnt/premium-rwo# dd if=file1 of=file2 bs=8k count=250000 && sync 
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 38.7144 s, 52.9 MB/s

root@nginx:/mnt/premium-rwo# time ( ls -l && rm -f file1 file2 )
total 4000028
-rw-r--r-- 1 root   root    2048000000 May 17 23:52 file1
-rw-r--r-- 1 root   root    2048000000 May 17 23:53 file2
real    0m0.184s
user    0m0.002s
sys     0m0.050s

root@nginx:/mnt/premium-rwo# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    0m4.073s
user    0m0.521s
sys     0m0.403s

real    0m3.880s
user    0m0.507s
sys     0m0.360s

real    0m5.661s
user    0m0.520s
sys     0m0.357s

real    0m3.804s
user    0m0.510s
sys     0m0.355s

real    0m3.796s
user    0m0.518s
sys     0m0.342s

root@nginx:/mnt/premium-rwo# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m0.278s
user    0m0.005s
sys     0m0.079s
```

# Delete the cluster

```bash
./gcp-cluster.sh delete mycluster
```