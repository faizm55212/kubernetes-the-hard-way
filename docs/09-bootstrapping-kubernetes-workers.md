# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap two Kubernetes worker nodes. The following components will be installed: [runc](https://github.com/opencontainers/runc), [container networking plugins](https://github.com/containernetworking/cni), [containerd](https://github.com/containerd/containerd), [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet), and [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

## Prerequisites

The commands in this section must be run from the `jumpbox`.

Copy the Kubernetes binaries and systemd unit files to each worker instance:

```bash
for HOST in worker-0 worker-1; do
  ssh -i /kthwLab/ssh/id_rsa root@${HOST} \
      mkdir -p /etc/cni/net.d /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes

  SUBNET=$(grep ${HOST} /kthwLab/machines.txt | cut -d " " -f 4)
  sed "s|SUBNET|$SUBNET|g" \
    /kthwLab/kubernetes-the-hard-way/configs/10-bridge.conf > 10-bridge.conf

  scp -i /kthwLab/ssh/id_rsa 10-bridge.conf \
  root@${HOST}:/etc/cni/net.d/

  scp -i /kthwLab/ssh/id_rsa /kthwLab/kubernetes-the-hard-way/configs/kubelet-config.yaml \
  root@${HOST}:/var/lib/kubelet/kubelet-config.yaml
  rm 10-bridge.conf
done
```

```bash
for HOST in worker-0 worker-1; do
  ssh -i /kthwLab/ssh/id_rsa root@${HOST} mkdir -p /var/lib/kube-proxy/ /etc/containerd/
  scp -i /kthwLab/ssh/id_rsa \
    /kthwLab/Downloads/worker/crictl /kthwLab/Downloads/worker/kube-proxy \
    /kthwLab/Downloads/worker/kubelet /kthwLab/Downloads/worker/runc \
    /kthwLab/Downloads/client/kubectl \
    root@${HOST}:/usr/local/bin/
  scp -i /kthwLab/ssh/id_rsa \
    /kthwLab/Downloads/worker/containerd /kthwLab/Downloads/worker/containerd-shim-runc-v2\
    /kthwLab/Downloads/worker/containerd-stress \
    root@${HOST}:/bin/
  scp -i /kthwLab/ssh/id_rsa \
    /kthwLab/Downloads/worker/ctr \
    root@${HOST}:~/
  scp -i /kthwLab/ssh/id_rsa \
    /kthwLab/kubernetes-the-hard-way/units/containerd.service \
    /kthwLab/kubernetes-the-hard-way/units/kubelet.service \
    /kthwLab/kubernetes-the-hard-way/units/kube-proxy.service \
    root@${HOST}:/etc/systemd/system/
  scp -i /kthwLab/ssh/id_rsa \
    /kthwLab/kubernetes-the-hard-way/configs/99-loopback.conf \
    root@${HOST}:/etc/cni/net.d/
  scp -i /kthwLab/ssh/id_rsa \
    /kthwLab/kubernetes-the-hard-way/configs/containerd-config.toml \
    root@${HOST}:/etc/containerd/config.toml
  scp -i /kthwLab/ssh/id_rsa \
    /kthwLab/kubernetes-the-hard-way/configs/kube-proxy-config.yaml \
    root@${HOST}:/var/lib/kube-proxy/
done
```

```bash
for HOST in worker-0 worker-1; do
  ssh -i /kthwLab/ssh/id_rsa root@${HOST} mkdir -p /opt/cni/bin
  scp -i /kthwLab/ssh/id_rsa \
    /kthwLab/Downloads/cni-plugins/* \
    root@${HOST}:/opt/cni/bin/
done
```

The commands in the next section must be run on each worker instance: `worker-0`, `worker-1`. Login to the worker instance using the `ssh` command. Example:

```bash
ssh -i /kthwLab/ssh/id_rsa root@worker-0
```

## Provisioning a Kubernetes Worker Node

Install the OS dependencies:

```bash
apt-get -y install socat conntrack ipset kmod
```

> The socat binary enables support for the `kubectl port-forward` command.

Disable Swap

Kubernetes has limited support for the use of swap memory, as it is difficult to provide guarantees and account for pod memory utilization when swap is involved.

Verify if swap is disabled:

```bash
swapon --show
```

If output is empty then swap is disabled. If swap is enabled run the following command to disable swap immediately:

```bash
swapoff -a
```

> To ensure swap remains off after reboot consult your Linux distro documentation.

To ensure network traffic crossing the CNI `bridge` network is processed by `iptables`, load and configure the `br-netfilter` kernel module:

```bash
modprobe br-netfilter
echo "br-netfilter" >> /etc/modules-load.d/modules.conf
```

```bash
echo "net.bridge.bridge-nf-call-iptables = 1" \
    >> /etc/sysctl.d/kubernetes.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" \
    >> /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf
```

### Start the Worker Services

```bash
systemctl daemon-reload
systemctl enable containerd kubelet kube-proxy
systemctl start containerd kubelet kube-proxy
```

Check if the kubelet service is running:

```bash
systemctl is-active kubelet
```

```text
active
```

Be sure to complete the steps in this section on each worker node, `worker-0` and `worker-1`, before moving on to the next section.

## Verification

Run the following commands from the `jumpbox` machine.

List the registered Kubernetes nodes:

```bash
ssh -i /kthwLab/ssh/id_rsa root@server-0 \
  "kubectl get nodes --kubeconfig admin.kubeconfig"
```

```
NAME     STATUS   ROLES    AGE    VERSION
worker-0   Ready    <none>   1m     v1.32.3
worker-1   Ready    <none>   10s    v1.32.3
```

Next: [Configuring kubectl for Remote Access](10-configuring-kubectl.md)
