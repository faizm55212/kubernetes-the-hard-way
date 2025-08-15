# Download Binaries

In this lab we will download the binaries for the various Kubernetes components. The binaries will be stored in the `/kthwLab/Downloads` directory, which will reduce the amount of internet bandwidth required to complete this tutorial as we avoid downloading the binaries multiple times for each machine in our Kubernetes cluster.

Download the binaries into a directory called `/kthwLab/Downloads` using the `wget` command:

```bash
wget -q --show-progress \
  --https-only \
  --timestamping \
  -P /kthwLab/Downloads \
  -i /kthwLab/kubernetes-the-hard-way/downloads-amd64.txt
```

Depending on your internet connection speed it may take a while to download over `500` megabytes of binaries, and once the download is complete, you can list them using the `ls` command:

```bash
ls -oh /kthwLab/Downloads
```

Extract the component binaries from the release archives and organize them under the `/kthwLab/Downloads` directory.

```bash
mkdir -p /kthwLab/Downloads/{client,cni-plugins,controller,worker}
tar -xvf /kthwLab/Downloads/crictl-v1.32.0-linux-amd64.tar.gz \
  -C /kthwLab/Downloads/worker/
tar -xvf /kthwLab/Downloads/containerd-2.1.0-beta.0-linux-amd64.tar.gz \
  --strip-components 1 \
  -C /kthwLab/Downloads/worker/
tar -xvf /kthwLab/Downloads/cni-plugins-linux-amd64-v1.6.2.tgz \
  -C /kthwLab/Downloads/cni-plugins/
tar -xvf /kthwLab/Downloads/etcd-v3.6.0-rc.3-linux-amd64.tar.gz \
  -C /kthwLab/Downloads/ \
  --strip-components 1 \
  etcd-v3.6.0-rc.3-linux-amd64/etcdctl \
  etcd-v3.6.0-rc.3-linux-amd64/etcd
mv /kthwLab/Downloads/{etcdctl,kubectl} /kthwLab/Downloads/client/
mv /kthwLab/Downloads/{etcd,kube-apiserver,kube-controller-manager,kube-scheduler} \
  /kthwLab/Downloads/controller/
mv /kthwLab/Downloads/{kubelet,kube-proxy} /kthwLab/Downloads/worker/
mv /kthwLab/Downloads/runc.amd64 /kthwLab/Downloads/worker/runc
```

```bash
rm -rf /kthwLab/Downloads/*gz
```

Make the binaries executable.

```bash
chmod +x /kthwLab/Downloads/{client,cni-plugins,controller,worker}/*
```

### Install kubectl

In this section you will install the `kubectl`, the official Kubernetes client command line tool, on the `jumpbox` machine. `kubectl` will be used to interact with the Kubernetes control plane once your cluster is provisioned later in this tutorial.

Use the `chmod` command to make the `kubectl` binary executable and move it to the `/usr/local/bin/` directory:

```bash
cp /kthwLab/Downloads/client/kubectl /usr/local/bin/
```

At this point `kubectl` is installed and can be verified by running the `kubectl` command:

```bash
kubectl version --client
```

```text
Client Version: v1.32.3
Kustomize Version: v5.5.0
```

At this point all the command line tools and utilities necessary to complete the labs in this tutorial are downloaded and contegorized.

Next: [Provisioning Compute Resources](03-compute-resources.md)
