# Bootstrapping the etcd Cluster

Kubernetes components are stateless and store cluster state in [etcd](https://github.com/etcd-io/etcd). In this lab you will bootstrap a single node etcd cluster.

## Prerequisites

Copy `etcd` binaries and systemd unit files to the `server-0` machine:

```bash
scp -i /kthwLab/ssh/id_rsa \
  /kthwLab/Downloads/controller/etcd \
  /kthwLab/Downloads/client/etcdctl \
  root@server-0:/usr/local/bin/
scp -i /kthwLab/ssh/id_rsa \
  /kthwLab/kubernetes-the-hard-way/units/etcd.service \
  root@server-0:/etc/systemd/system/
```

The commands in this lab must be run on the `server-0` machine. Login to the `server-0` machine using the `ssh` command. Example:

```bash
ssh -i /kthwLab/ssh/id_rsa root@server-0
```

### Configure the etcd Server

```bash
mkdir -p /var/lib/etcd
chmod 700 /var/lib/etcd
```

Each etcd member must have a unique name within an etcd cluster. Set the etcd name to match the hostname of the current compute instance:

### Start the etcd Server

```bash
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

## Verification

List the etcd cluster members:

```bash
etcdctl member list
```

```text
6702b0a34e2cfd39, started, controller, http://127.0.0.1:2380, http://127.0.0.1:2379, false
```

Next: [Bootstrapping the Kubernetes Control Plane](08-bootstrapping-kubernetes-controllers.md)
