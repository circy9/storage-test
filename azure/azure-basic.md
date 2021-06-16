# Create a cluster

```bash
./azure-cluster.sh create cluster AKSTest
```

# Run dbench tests: single

## Test steps

```bash
./run-dbench-test.sh -t azure-basic-dbench-default
```

## Test results

```bash
tail results/azure-basic-dbench-default-output.txt
```

# Run dbench tests: multiple

## Test steps

```bash
./azure-basic-run-dbench-tests.sh
```

## Test results

See results/{storage-class}-{storage-capacity}-output.txt.

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f disk/storage-class.yaml
kubectl apply -f azure-basic.yaml

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

### Storage Class "disk-no-cache"

```bash
root@nginx:/mnt/disk-no-cache# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 19.3077 s, 106 MB/s

root@nginx:/mnt/disk-no-cache# dd if=file1 of=file2 bs=8k count=250000 && sync 
048000000 bytes (2.0 GB, 1.9 GiB) copied, 45.9554 s, 44.6 MB/s

root@nginx:/mnt/disk-no-cache# time ( ls -l && rm -f file1 file2 )
real    0m0.227s
user    0m0.002s
sys     0m0.075s

root@nginx:/mnt/disk-no-cache# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
real    0m3.249s
user    0m0.447s
sys     0m0.205s

real    0m3.292s
user    0m0.457s
sys     0m0.245s

root@nginx:/mnt/disk-no-cache# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m0.156s
user    0m0.016s
sys     0m0.046s

real    0m0.196s
user    0m0.012s
sys     0m0.053s
```

### Storage Class "default"

```bash
root@nginx:/mnt/default# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.0808 s, 157 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.0825 s, 157 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.1222 s, 156 MB/s

root@nginx:/mnt/default# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.6542 s, 86.6 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.5843 s, 86.8 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.6928 s, 86.4 MB/s

root@nginx:/mnt/default# time ( ls -l && rm -f file1 file2 )
total 4000024
-rw-r--r-- 1 root root 2048000000 May 19 21:17 file1
-rw-r--r-- 1 root root 2048000000 May 19 21:17 file2
drwx------ 2 root root      16384 May 19 21:12 lost+found

real    0m0.312s
user    0m0.003s
sys     0m0.087s

real    0m0.312s
user    0m0.002s
sys     0m0.086s

real    0m0.277s
user    0m0.003s
sys     0m0.086s

root@nginx:/mnt/default# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    0m3.610s
user    0m0.536s
sys     0m0.272s

real    0m3.709s
user    0m0.528s
sys     0m0.284s

real    0m3.603s
user    0m0.522s
sys     0m0.265s

root@nginx:/mnt/default# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m0.297s
user    0m0.004s
sys     0m0.063s

real    0m0.288s
user    0m0.007s
sys     0m0.057s

real    0m0.296s
user    0m0.004s
sys     0m0.063s
```

### Storage Class "managed-premium"

```bash
root@nginx:/mnt/managed-premium# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 11.715 s, 175 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 11.5616 s, 177 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 12.5266 s, 163 MB/s

root@nginx:/mnt/managed-premium# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.7655 s, 86.2 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.8254 s, 86.0 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.7439 s, 86.3 MB/s

root@nginx:/mnt/managed-premium# time ( ls -l && rm -f file1 file2 )
total 4000024
-rw-r--r-- 1 root root 2048000000 May 19 21:25 file1
-rw-r--r-- 1 root root 2048000000 May 19 21:26 file2
drwx------ 2 root root      16384 May 19 21:12 lost+found

real    0m0.249s
user    0m0.001s
sys     0m0.091s

real    0m0.289s
user    0m0.003s
sys     0m0.086s

real    0m0.317s
user    0m0.003s
sys     0m0.089s

root@nginx:/mnt/managed-premium# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    0m3.790s
user    0m0.518s
sys     0m0.296s

real    0m3.595s
user    0m0.515s
sys     0m0.267s

real    0m3.696s
user    0m0.532s
sys     0m0.265s

root@nginx:/mnt/managed-premium# time ( du wordpress/ | tail -1 && rm -rf wordpress )
57792   wordpress/

real    0m0.213s
user    0m0.008s
sys     0m0.054s

real    0m0.291s
user    0m0.005s
sys     0m0.055s

real    0m0.206s
user    0m0.008s
sys     0m0.052s
```

### Storage Class "azurefile"

```bash
root@nginx:/mnt/azurefile# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 14.6194 s, 140 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.8597 s, 148 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 14.7587 s, 139 MB/s

root@nginx:/mnt/azurefile# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 34.4356 s, 59.5 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 33.5947 s, 61.0 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 31.1823 s, 65.7 MB/s

root@nginx:/mnt/azurefile# time ( ls -l && rm -f file1 file2 )
total 4000000
-rwxrwxrwx 1 root root 2048000000 May 19 21:30 file1
-rwxrwxrwx 1 root root 2048000000 May 19 21:31 file2

real    0m0.320s
user    0m0.002s
sys     0m0.086s

real    0m0.322s
user    0m0.002s
sys     0m0.089s

real    0m0.320s
user    0m0.001s
sys     0m0.091s

root@nginx:/mnt/azurefile# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    5m22.096s
user    0m0.763s
sys     0m2.270s

real    4m3.166s
user    0m0.745s
sys     0m2.288s

real    2m54.933s
user    0m0.718s
sys     0m2.203s

real    3m25.603s
user    0m0.735s
sys     0m2.264s

root@nginx:/mnt/azurefile# time ( du wordpress/ | tail -1 && rm -rf wordpress )
52034   wordpress/

real    0m43.056s
user    0m0.054s
sys     0m0.503s

real    0m40.370s
user    0m0.022s
sys     0m0.515s

real    0m37.261s
user    0m0.036s
sys     0m0.526s

real    0m43.230s
user    0m0.050s
sys     0m0.464s
```

### Storage Class "azurefile-premium"

```bash
root@nginx:/mnt/azurefile-premium# dd if=/dev/zero of=file1 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.9678 s, 147 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.6612 s, 150 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 13.4534 s, 152 MB/s

root@nginx:/mnt/azurefile-premium# dd if=file1 of=file2 bs=8k count=250000 && sync 
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 23.5375 s, 87.0 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 25.6296 s, 79.9 MB/s
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 24.1881 s, 84.7 MB/s

root@nginx:/mnt/azurefile-premium# time ( ls -l && rm -f file1 file2 )
total 4000000
-rwxrwxrwx 1 root root 2048000000 May 20 00:03 file1
-rwxrwxrwx 1 root root 2048000000 May 20 00:04 file2

real    0m0.257s
user    0m0.001s
sys     0m0.085s

real    0m0.292s
user    0m0.005s
sys     0m0.084s

real    0m0.323s
user    0m0.002s
sys     0m0.086s

root@nginx:/mnt/azurefile-premium# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    1m19.984s
user    0m0.706s
sys     0m1.886s

real    1m19.745s
user    0m0.672s
sys     0m1.860s

real    1m20.518s
user    0m0.633s
sys     0m1.831s

root@nginx:/mnt/azurefile-premium# time ( du wordpress/ | tail -1 && rm -rf wordpress )
52034   wordpress/

real    0m24.080s
user    0m0.054s
sys     0m0.411s

real    0m24.137s
user    0m0.019s
sys     0m0.470s

real    0m24.213s
user    0m0.025s
sys     0m0.428s
```

# Run manual fio tests
Set up:

```bash
kubectl apply -f disk/storage-class.yaml
kubectl apply -f azure-basic-fio.yaml
kubectl -it exec pod/fio -- sh
```

Sample test:

```bash
cd /mnt/default

fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=read_iops --filename=./fiotest --bs=4K --iodepth=64 --size=2G --readwrite=randread --time_based --ramp_time=2s --runtime=15s

read_iops: (g=0): rw=randread, bs=4096B-4096B,4096B-4096B,4096B-4096B, ioengine=libaio, iodepth=64
fio-2.17-45-g06cb
Starting 1 process
Jobs: 1 (f=1): [r(1)][100.0%][r=2376KiB/s,w=0KiB/s][r=594,w=0 IOPS][eta 00m:00s]
read_iops: (groupid=0, jobs=1): err= 0: pid=29: Wed Jun 16 16:53:07 2021
   read: IOPS=594, BW=2396KiB/s (2454kB/s)(35.5MiB/15149msec)
  cpu          : usr=0.41%, sys=0.96%, ctx=4528, majf=0, minf=1
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.2%, 32=0.4%, >=64=113.6%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwt: total=9013,0,0, short=0,0,0, dropped=0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=2396KiB/s (2454kB/s), 2396KiB/s-2396KiB/s (2454kB/s-2454kB/s), io=35.5MiB (37.2MB), run=15149-15149msec

Disk stats (read/write):
  sde: ios=10200/0, merge=0/0, ticks=1082600/0, in_queue=1065260, util=99.31%
```

# Delete the cluster

```bash
./azure-cluster.sh delete cluster AKSTest
```

# FAQ

* Error: The subscription is not registered to use namespace 'Microsoft.Storage'. See https://aka.ms/rps-not-found for how to register subscriptions."

...Solution: Register for Microsoft.Storage following: https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/error-register-resource-provider

* Error: storage.FileSharesClient#Create: Failure responding to request: StatusCode=400 -- Original Error: autorest/azure: Service returned an error. Status=400 Code="InvalidHeaderValue" Message="The value for one of the HTTP headers is not in the correct format.\nRequestId:e50728d6-e01a-00f7-21ea-4c5041000000\nTime:2021-05-19T20:03:58.8105248Z

...Root cause: azurefile-premium requires at least 100GB: https://docs.microsoft.com/en-us/azure/aks/azure-files-dynamic-pv

...Solution: Set storage capacity in the persistent volume claim to be 100GB or
   more.
