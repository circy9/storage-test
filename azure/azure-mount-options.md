# Create a cluster with custom storage classes for azure files with different mount options

```bash
./azure-cluster.sh create cluster AKSTest
kubectl apply -f azure-mount-options-classes.yaml
```

# Run manual tests

## Test steps

```bash
# 1. Create a pod.
kubectl apply -f azure-mount-options.yaml

# 2. Install wget.
kubectl -it exec pod/nginx -- bash
apt update && apt install wget

# 3. Go to /mnt/X.
cd /mnt/X

# 4. Download and unzip files.
time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
time ( du wordpress/ | tail -1 && rm -rf wordpress )

Here are the sizes of the file before and after unzip:
16M     latest.tar.gz
56M     wordpress
52034   wordpress/

# 5. Delete the pod.
kubectl delete -f azure-mount-options.yaml
```

## Test results

```bash
root@nginx:/mnt/noserverino# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    5m30.789s
user    0m0.780s
sys     0m2.047s

root@nginx:/mnt/loose30# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    6m2.175s
user    0m0.807s
sys     0m2.555s

root@nginx:/mnt/loose0# time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )

real    8m3.323s
user    0m0.780s
sys     0m4.081s
```