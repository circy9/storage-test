# Create a cluster with 2 nodes
```
../azure-cluster.sh create dluster DiskTest 2
```

# Test 1: Will the disk be detached if we delete the corresponding pod? Yes!

## Create a pod with a pvc.
```
kubectl apply -f nginx-pod.yaml
```

## Verifed that Disk is attached to instance 1.
```
az vmss list-instances --resource-group=MC_DiskTest_dluster_westus --name=aks-nodepool1-25399436-vmss | grep -A 1 dataDisks
      "dataDisks": [],
      "dataDisks": [
```

## Delete pod.
```
kubectl delete po/nginx
```

## Verified that Disk is no longer attached.
```
az vmss list-instances --resource-group=MC_DiskTest_dluster_westus --name=aks-nodepool1-25399436-vmss | grep -A 1 dataDisks
      "dataDisks": [],
      "dataDisks": [],
```

## Clean up
```
kubectl delete -f nginx-pod.yaml
```

# Test 2: How long does it take for a pod with a PVC to move from one instance (manutally killed) to another? ~15 minutes.

## Create a one-pod stateful set with a pvc.
```
kubectl apply -f nginx-stateful-set.yaml
kubectl describe po
Events:
  Type    Reason                  Age   From                     Message
  ----    ------                  ----  ----                     -------
  Normal  Scheduled               19s   default-scheduler        Successfully assigned default/nginx-0 to aks-nodepool1-25399436-vmss000000
  Normal  SuccessfulAttachVolume  8s    attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-076e1d98-d915-42bc-9b8a-40ca6d8983e8"
  Normal  Pulling                 2s    kubelet                  Pulling image "nginx"
  Normal  Pulled                  1s    kubelet                  Successfully pulled image "nginx" in 799.435065ms
  Normal  Created                 1s    kubelet                  Created container nginx
  Normal  Started                 1s    kubelet                  Started container nginx
```

11 seconds to attach the disk.

## Make sure we have two instances.
```
export RG=MC_DISKTEST_DCLUSTER_WESTUS
export VMSS=aks-nodepool1-37131424-vmss
az vmss scale --resource-group ${RG} --name ${VMSS} --new-capacity 2
az vmss list-instances --resource-group ${RG} --name ${VMSS} -o table
```

## Delete the instance running the pod.

```
# Get the service external IP.
kubectl get service

# Ping the external IP.
export IP=104.45.209.49
while true; do nc -vz -w 1 ${IP} 80; date; sleep 1; done;

# Delete the instance. 
az vmss delete-instances --instance-ids 0 --name ${VMSS} --resource-group ${RG} && date
Mon Jun  7 15:55:28 PDT 2021
```

## Verified that Disk is attached to instance 1.

Pod stayed at NodeNotReady for x minuts.
Pod was shown as status "running".
Can't connect to the pod.
```
❯ kubectl describe po
Events:
  Type     Reason                  Age    From                     Message
  ----     ------                  ----   ----                     -------
  Normal   Scheduled               11m    default-scheduler        Successfully assigned default/nginx-0 to aks-nodepool1-25399436-vmss000000
  Normal   SuccessfulAttachVolume  10m    attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-076e1d98-d915-42bc-9b8a-40ca6d8983e8"
  Normal   Pulling                 10m    kubelet                  Pulling image "nginx"
  Normal   Pulled                  10m    kubelet                  Successfully pulled image "nginx" in 799.435065ms
  Normal   Created                 10m    kubelet                  Created container nginx
  Normal   Started                 10m    kubelet                  Started container nginx
  Warning  NodeNotReady            4m29s  node-controller          Node is not ready

❯ kubectl get po
NAME      READY   STATUS    RESTARTS   AGE
nginx-0   1/1     Running   0          11m

❯ kubectl get po
NAME      READY   STATUS    RESTARTS   AGE
nginx-0   1/1     Running   0          13m

❯ kubectl -it exec nginx-0 -- bash
Error from server: error dialing backend: dial tcp 10.240.0.4:10250: connect: no route to host

❯ kubectl -it exec nginx-0 -- bash
Error from server (NotFound): pods "aks-nodepool1-25399436-vmss000000" not found

❯ kubectl get po
NAME      READY   STATUS        RESTARTS   AGE
nginx-0   1/1     Terminating   0          15m

❯ kubectl describe po
Events:
  Type     Reason              Age   From                     Message
  ----     ------              ----  ----                     -------
  Normal   Scheduled           119s  default-scheduler        Successfully assigned default/nginx-0 to aks-nodepool1-25399436-vmss000003
  Warning  FailedAttachVolume  119s  attachdetach-controller  Multi-Attach error for volume "pvc-076e1d98-d915-42bc-9b8a-40ca6d8983e8" Volume is already exclusively attached to one node and can't be attached to another

❯ kubectl describe po/nginx-0
Events:
  Type     Reason                  Age                    From                     Message
  ----     ------                  ----                   ----                     -------
  Normal   Scheduled               9m7s                   default-scheduler        Successfully assigned default/nginx-0 to aks-nodepool1-25399436-vmss000000
  Warning  FailedAttachVolume      9m7s                   attachdetach-controller  Multi-Attach error for volume "pvc-076e1d98-d915-42bc-9b8a-40ca6d8983e8" Volume is already exclusively attached to one node and can't be attached to another
  Warning  FailedMount             7m4s                   kubelet                  Unable to attach or mount volumes: unmounted volumes=[default], unattached volumes=[default kube-api-access-wxgbr]: timed out waiting for the condition
  Normal   SuccessfulAttachVolume  2m55s                  attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-076e1d98-d915-42bc-9b8a-40ca6d8983e8"
  Warning  FailedMount             2m33s (x2 over 4m48s)  kubelet                  Unable to attach or mount volumes: unmounted volumes=[default], unattached volumes=[kube-api-access-wxgbr default]: timed out waiting for the condition
  Normal   Pulling                 51s                    kubelet                  Pulling image "nginx"
  Normal   Pulled                  46s                    kubelet                  Successfully pulled image "nginx" in 5.150304782s
  Normal   Created                 44s                    kubelet                  Created container nginx
  Normal   Started                 44s                    kubelet                  Started container nginx
```

It took 15 minutes to fail over to another node. Based on the ping, the service is unreachable for 15 minutes.

Event summary:
*  19m: Node 3 is ready
*  15m: Node 0 (running the pod) is deleted.
*  10m: Mark for deletion of the pod.
*  9m: Remove node 0.
*  8m30: Pod created in node 3.
*  8m30 - 14s: Trying to attach the disk.
*  14s: Pull image.
*  7s: Pod started.

```
kubectl get events --sort-by='.lastTimestamp'
19m         Normal    RegisteredNode            node/aks-nodepool1-25399436-vmss000003   Node aks-nodepool1-25399436-vmss000003 event: Registered Node aks-nodepool1-25399436-vmss000003 in Controller
19m         Normal    Starting                  node/aks-nodepool1-25399436-vmss000003   Starting kube-proxy.
19m         Normal    NodeReady                 node/aks-nodepool1-25399436-vmss000003   Node aks-nodepool1-25399436-vmss000003 status is now: NodeReady
15m         Normal    NodeNotReady              node/aks-nodepool1-25399436-vmss000000   Node aks-nodepool1-25399436-vmss000000 status is now: NodeNotReady
15m         Warning   NodeNotReady              pod/nginx-0                              Node is not ready
15m         Normal    UpdatedLoadBalancer       service/nginx                            Updated load balancer with new hosts
10m         Normal    TaintManagerEviction      pod/nginx-0                              Marking for deletion Pod default/nginx-0
9m11s       Normal    DeletingNode              node/aks-nodepool1-25399436-vmss000000   Deleting node aks-nodepool1-25399436-vmss000000 because it does not exist in the cloud provider
9m9s        Normal    RemovingNode              node/aks-nodepool1-25399436-vmss000000   Node aks-nodepool1-25399436-vmss000000 event: Removing Node aks-nodepool1-25399436-vmss000000 from Controller
8m30s       Warning   FailedAttachVolume        pod/nginx-0                              Multi-Attach error for volume "pvc-076e1d98-d915-42bc-9b8a-40ca6d8983e8" Volume is already exclusively attached to one node and can't be attached to another
8m30s       Normal    Scheduled                 pod/nginx-0                              Successfully assigned default/nginx-0 to aks-nodepool1-25399436-vmss000003
8m30s       Normal    SuccessfulCreate          statefulset/nginx                        create Pod nginx-0 in StatefulSet nginx successful
6m27s       Warning   FailedMount               pod/nginx-0                              Unable to attach or mount volumes: unmounted volumes=[default], unattached volumes=[kube-api-access-8hdkh default]: timed out waiting for the condition
2m18s       Normal    SuccessfulAttachVolume    pod/nginx-0                              AttachVolume.Attach succeeded for volume "pvc-076e1d98-d915-42bc-9b8a-40ca6d8983e8"
117s        Warning   FailedMount               pod/nginx-0                              Unable to attach or mount volumes: unmounted volumes=[default], unattached volumes=[default kube-api-access-8hdkh]: timed out waiting for the condition
14s         Normal    Pulling                   pod/nginx-0                              Pulling image "nginx"
9s          Normal    Pulled                    pod/nginx-0                              Successfully pulled image "nginx" in 4.976063719s
7s          Normal    Started                   pod/nginx-0                              Started container nginx
7s          Normal    Created                   pod/nginx-0                              Created container nginx

Output of ping
❯ while true; do nc -vz -w 1 40.112.188.4 80; date; sleep 1; done;"
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Connection refused
Sun Jun  6 20:05:12 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:06:28 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:07:45 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:09:01 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:10:17 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:11:34 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:12:51 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:14:07 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:15:24 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:16:40 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:17:57 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:19:13 PDT 2021
nc: connectx to 40.112.188.4 port 80 (tcp) failed: Operation timed out
Sun Jun  6 20:20:29 PDT 2021
Connection to 40.112.188.4 port 80 [tcp/http] succeeded!
Sun Jun  6 20:21:06 PDT 2021
Connection to 40.112.188.4 port 80 [tcp/http] succeeded!
Sun Jun  6 20:21:07 PDT 2021
Connection to 40.112.188.4 port 80 [tcp/http] succeeded!
```

## Clean up.
```
kubectl delete -f nginx-stateful-set.yaml
```

## Result from a second run

```
❯ while true; do nc -vz -w 1 ${IP} 80; date; sleep 1; done;
Connection to 104.45.209.49 port 80 [tcp/http] succeeded!
Mon Jun  7 15:54:34 PDT 2021
nc: connectx to 104.45.209.49 port 80 (tcp) failed: Connection refused
Mon Jun  7 15:54:51 PDT 2021
nc: connectx to 104.45.209.49 port 80 (tcp) failed: Operation timed out
Mon Jun  7 15:56:07 PDT 2021
nc: connectx to 104.45.209.49 port 80 (tcp) failed: Operation timed out
Mon Jun  7 15:57:24 PDT 2021
nc: connectx to 104.45.209.49 port 80 (tcp) failed: Operation timed out
Mon Jun  7 15:58:40 PDT 2021
nc: connectx to 104.45.209.49 port 80 (tcp) failed: Operation timed out
Mon Jun  7 15:59:56 PDT 2021
nc: connectx to 104.45.209.49 port 80 (tcp) failed: Operation timed out
Mon Jun  7 16:01:13 PDT 2021
nc: connectx to 104.45.209.49 port 80 (tcp) failed: Operation timed out
Mon Jun  7 16:02:29 PDT 2021
nc: connectx to 104.45.209.49 port 80 (tcp) failed: Operation timed out
Mon Jun  7 16:03:45 PDT 2021
Connection to 104.45.209.49 port 80 [tcp/http] succeeded!
Mon Jun  7 16:04:54 PDT 2021
Connection to 104.45.209.49 port 80 [tcp/http] succeeded!
Mon Jun  7 16:04:55 PDT 2021
```

```
❯ kubectl get events --sort-by='.lastTimestamp'
17m         Normal    SuccessfulCreate          statefulset/nginx                                      create Claim default-nginx-0 Pod nginx-0 in StatefulSet nginx success
17m         Normal    ProvisioningSucceeded     persistentvolumeclaim/default-nginx-0                  Successfully provisioned volume pvc-4ccf6b30-a445-415a-98f2-35cef3c030ae
17m         Normal    Scheduled                 pod/nginx-0                                            Successfully assigned default/nginx-0 to aks-nodepool1-37131424-vmss000000
17m         Normal    SuccessfulAttachVolume    pod/nginx-0                                            AttachVolume.Attach succeeded for volume "pvc-4ccf6b30-a445-415a-98f2-35cef3c030ae"
17m         Normal    EnsuredLoadBalancer       service/nginx                                          Ensured load balancer
16m         Normal    Pulling                   pod/nginx-0                                            Pulling image "nginx"
16m         Normal    Pulled                    pod/nginx-0                                            Successfully pulled image "nginx" in 5.939936495s
16m         Normal    Created                   pod/nginx-0                                            Created container nginx
16m         Normal    Started                   pod/nginx-0                                            Started container nginx
10m         Warning   NodeNotReady              pod/nginx-0                                            Node is not ready
10m         Normal    NodeNotReady              node/aks-nodepool1-37131424-vmss000000                 Node aks-nodepool1-37131424-vmss000000 status is now: NodeNotReady
10m         Normal    UpdatedLoadBalancer       service/nginx                                          Updated load balancer with new hosts
10m         Normal    RemovingNode              node/aks-nodepool1-37131424-vmss000000                 Node aks-nodepool1-37131424-vmss000000 event: Removing Node aks-nodepool1-37131424-vmss000000 from Controller
10m         Normal    DeletingNode              node/aks-nodepool1-37131424-vmss000000                 Deleting node aks-nodepool1-37131424-vmss000000 because it does not exist in the cloud provider
9m51s       Warning   FailedAttachVolume        pod/nginx-0                                            Multi-Attach error for volume "pvc-4ccf6b30-a445-415a-98f2-35cef3c030ae" Volume is already exclusively attached to one node and can't be attached to another
9m51s       Normal    SuccessfulCreate          statefulset/nginx                                      create Pod nginx-0 in StatefulSet nginx successful
9m51s       Normal    Scheduled                 pod/nginx-0                                            Successfully assigned default/nginx-0 to aks-nodepool1-37131424-vmss000001
3m34s       Normal    SuccessfulAttachVolume    pod/nginx-0                                            AttachVolume.Attach succeeded for volume "pvc-4ccf6b30-a445-415a-98f2-35cef3c030ae"
3m14s       Warning   FailedMount               pod/nginx-0                                            Unable to attach or mount volumes: unmounted volumes=[default], unattached volumes=[default kube-api-access-ptvn5]: timed out waiting for the condition
94s         Normal    Pulling                   pod/nginx-0                                            Pulling image "nginx"
89s         Normal    Pulled                    pod/nginx-0                                            Successfully pulled image "nginx" in 5.531561241s
86s         Normal    Started                   pod/nginx-0                                            Started container nginx
86s         Normal    Created                   pod/nginx-0                                            Created container nginx
```

# Delete the cluster.
```
../azure-cluster.sh delete dluster DiskTest
```
