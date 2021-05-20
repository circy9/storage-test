# Deploy

```bash
# Deploy NFS provisioner
kubectl create -f psp.yaml
kubectl create -f rbac.yaml
kubectl create -f statefulset.yaml

# Create storage class
kubectl create -f class.yaml
```

# Verify

```bash
# Create a file called HELLO.
kubectl apply -f test.yaml
kubectl -it exec pod/nginx -- bash -c "touch /mnt/nfs/HELLO"

# Verify the file HELLO exists.
kubectl delete pod/nginx
kubectl apply -f test.yaml
kubectl -it exec pod/nginx -- bash -c "ls /mnt/nfs"

# Clean up
kubectl delete -f test.yaml
```

# Clean up

```bash
# Delete storage class
kubectl delete -f class.yaml

# Delete NFS provisioner
kubectl delete -f statefulset.yaml
kubectl delete -f rbac.yaml
kubectl delete -f psp.yaml
```




