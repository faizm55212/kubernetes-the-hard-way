# Generating Kubernetes Configuration Files for Authentication

In this lab you will generate [Kubernetes client configuration files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/), typically called kubeconfigs, which configure Kubernetes clients to connect and authenticate to Kubernetes API Servers.

## Client Authentication Configs

In this section you will generate kubeconfig files for the `kubelet` and the `admin` user.

### The kubelet Kubernetes Configuration File

When generating kubeconfig files for Kubelets the client certificate matching the Kubelet's node name must be used. This will ensure Kubelets are properly authorized by the Kubernetes [Node Authorizer](https://kubernetes.io/docs/reference/access-authn-authz/node/).

> The following commands must be run in the same directory used to generate the SSL certificates during the [Generating TLS Certificates](04-certificate-authority.md) lab.

```bash
cd /kthwLab/certs
```

Generate a kubeconfig file for the `worker-0` and `worker-1` worker nodes:

```bash
for host in worker-0 worker-1; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server-0.kubernetes.local:6443 \
    --kubeconfig=${host}/${host}.kubeconfig

  kubectl config set-credentials system:node:${host} \
    --client-certificate=${host}/${host}.crt \
    --client-key=${host}/${host}.key \
    --embed-certs=true \
    --kubeconfig=${host}/${host}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${host} \
    --kubeconfig=${host}/${host}.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${host}/${host}.kubeconfig
done
```

Results:

```text
worker-0.kubeconfig
worker-1.kubeconfig
```

### The kube-proxy Kubernetes Configuration File

Generate a kubeconfig file for the `kube-proxy` service:

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://server-0.kubernetes.local:6443 \
  --kubeconfig=kube-proxy/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy/kube-proxy.crt \
  --client-key=kube-proxy/kube-proxy.key \
  --embed-certs=true \
  --kubeconfig=kube-proxy/kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy/kube-proxy.kubeconfig

kubectl config use-context default \
  --kubeconfig=kube-proxy/kube-proxy.kubeconfig
```

Results:

```text
kube-proxy.kubeconfig
```

### The kube-controller-manager Kubernetes Configuration File

Generate a kubeconfig file for the `kube-controller-manager` service:

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://server-0.kubernetes.local:6443 \
  --kubeconfig=kube-controller-manager/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager/kube-controller-manager.crt \
  --client-key=kube-controller-manager/kube-controller-manager.key \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager/kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager/kube-controller-manager.kubeconfig

kubectl config use-context default \
  --kubeconfig=kube-controller-manager/kube-controller-manager.kubeconfig
```

Results:

```text
kube-controller-manager.kubeconfig
```


### The kube-scheduler Kubernetes Configuration File

Generate a kubeconfig file for the `kube-scheduler` service:

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://server-0.kubernetes.local:6443 \
  --kubeconfig=kube-scheduler/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler/kube-scheduler.crt \
  --client-key=kube-scheduler/kube-scheduler.key \
  --embed-certs=true \
  --kubeconfig=kube-scheduler/kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler/kube-scheduler.kubeconfig

kubectl config use-context default \
  --kubeconfig=kube-scheduler/kube-scheduler.kubeconfig
```

Results:

```text
kube-scheduler.kubeconfig
```

### The admin Kubernetes Configuration File

Generate a kubeconfig file for the `admin` user:

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin/admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin/admin.crt \
  --client-key=admin/admin.key \
  --embed-certs=true \
  --kubeconfig=admin/admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --kubeconfig=admin/admin.kubeconfig

kubectl config use-context default \
  --kubeconfig=admin/admin.kubeconfig
```

Results:

```text
admin.kubeconfig
```

## Distribute the Kubernetes Configuration Files

Copy the `kubelet` and `kube-proxy` kubeconfig files to the `worker-0` and `worker-1` machines:

```bash
for host in worker-0 worker-1; do
  ssh -i /kthwLab/ssh/id_rsa root@${host} "mkdir -p /var/lib/{kube-proxy,kubelet}"

  scp -i /kthwLab/ssh/id_rsa kube-proxy/kube-proxy.kubeconfig \
    root@${host}:/var/lib/kube-proxy/kubeconfig \

  scp -i /kthwLab/ssh/id_rsa ${host}/${host}.kubeconfig \
    root@${host}:/var/lib/kubelet/kubeconfig
done
```

Copy the `kube-controller-manager` and `kube-scheduler` kubeconfig files to the `server-0` machine:

```bash
ssh -i /kthwLab/ssh/id_rsa root@server-0 mkdir -p /var/lib/kubernetes/
scp -i /kthwLab/ssh/id_rsa \
  kube-controller-manager/kube-controller-manager.kubeconfig \
  kube-scheduler/kube-scheduler.kubeconfig \
  root@server-0:/var/lib/kubernetes/
scp -i /kthwLab/ssh/id_rsa admin/admin.kubeconfig \
  root@server-0:/root/
```

Next: [Generating the Data Encryption Config and Key](06-data-encryption-keys.md)
