# Generating the Data Encryption Config and Key

Kubernetes stores a variety of data including cluster state, application configurations, and secrets. Kubernetes supports the ability to [encrypt](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data) cluster data at rest.

In this lab you will generate an encryption key and an [encryption config](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration) suitable for encrypting Kubernetes Secrets.

## The Encryption Key

> The following commands must be run in the same directory used to generate the SSL certificates during the [Generating TLS Certificates](04-certificate-authority.md) lab.

```bash
cd /kthwLab/certs
```

Generate an encryption key:

```bash
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

## The Encryption Config File

Create the `encryption-config.yaml` encryption config file:

```bash
envsubst < /kthwLab/kubernetes-the-hard-way/configs/encryption-config.yaml \
  > encryption-config.yaml
```

Copy the `encryption-config.yaml` encryption config file to each controller instance:

```bash
ssh -i /kthwLab/ssh/id_rsa root@server-0 mkdir -p /var/lib/kubernetes/
scp -i /kthwLab/ssh/id_rsa encryption-config.yaml root@server-0:/var/lib/kubernetes/
rm encryption-config.yaml
```

Next: [Bootstrapping the etcd Cluster](07-bootstrapping-etcd.md)
