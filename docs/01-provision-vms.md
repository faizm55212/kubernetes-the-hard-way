## 💻 Provision VMs

In this lab we will create 3 virtual machines running Debian 13 (trixie), The following table lists the four machines and their CPU, memory, and storage requirements.

| Name      | Description            | CPU | RAM   | Storage |
|-----------|------------------------|-----|-------|---------|
| server    | Kubernetes server      | 1   | 2GB   | 20GB    |
| worker-0  | Kubernetes worker node | 1   | 2GB   | 20GB    |
| worker-1  | Kubernetes worker node | 1   | 2GB   | 20GB    |

### 📁 Directory Setup for Lab

Let's allocate a directory in / for this lab

```bash
sudo mkdir /kthwLab/
sudo chown $USER:$(id -gn) /kthwLab/
cd /kthwLab/
```

### 🔄 Sync GitHub Repository

Now it's time to download a copy of this tutorial which contains the configuration files and templates that will be used build your Kubernetes cluster from the ground up. Clone the Kubernetes The Hard Way git repository using the `git` command:

```bash
git clone git@github.com:faizm55212/kubernetes-the-hard-way.git
```

### 🚀 Creating Virtual Machines with QEMU

To provision the virtual machines, run the following script:

```bash
sudo /usr/bin/bash /kthwLab/kubernetes-the-hard-way/scripts/create-qemu-vms.sh
```
You can now ssh into these VMs using:
```bash
ssh -i /kthwLab/ssh/id_rsa root@server-0
ssh -i /kthwLab/ssh/id_rsa root@worker-0
ssh -i /kthwLab/ssh/id_rsa root@worker-1
```

Next: [download-binaries](02-download-binaries.md)
