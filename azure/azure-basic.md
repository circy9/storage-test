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

See results/azure-basic-dbench-default-output.txt.

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

# 6. Repeat 3-5 for /mnt/managed-premium, /mnt/azurefile and /mnt/azurefile-premium.

# 7. Delete the pod.
kubectl delete -f azure-basic.yaml
```

## Test results

### Storage Class "default"

```bash
```

### Storage Class "managed-premium"

```bash
```

### Storage Class "azurefile"

```bash
```

### Storage Class "azurefile-premium"

```bash
```

# Delete the cluster

```bash
./az.sh delete cluster AKSTest
```


