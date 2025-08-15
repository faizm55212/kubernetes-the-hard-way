# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network [routes](https://cloud.google.com/compute/docs/vpc/routes).

In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table

In this section you will gather the information required to create routes in the `kubernetes-the-hard-way` VPC network.

Print the internal IP address and Pod CIDR range for each worker instance:

```bash
SERVER_0_IP=$(grep server /kthwLab/machines.txt | cut -d " " -f 1)
WORKER_0_IP=$(grep worker-0 /kthwLab/machines.txt | cut -d " " -f 1)
WORKER_0_SUBNET=$(grep worker-0 /kthwLab/machines.txt | cut -d " " -f 4)
WORKER_1_IP=$(grep worker-1 /kthwLab/machines.txt | cut -d " " -f 1)
WORKER_1_SUBNET=$(grep worker-1 /kthwLab/machines.txt | cut -d " " -f 4)
```

```bash
ssh -i /kthwLab/ssh/id_rsa root@server-0 <<EOF
  ip route add ${WORKER_0_SUBNET} via ${WORKER_0_IP}
  ip route add ${WORKER_1_SUBNET} via ${WORKER_1_IP}
EOF
```

```bash
ssh -i /kthwLab/ssh/id_rsa root@worker-0 <<EOF
  ip route add ${WORKER_1_SUBNET} via ${WORKER_1_IP}
EOF
```

```bash
ssh -i /kthwLab/ssh/id_rsa root@worker-1 <<EOF
  ip route add ${WORKER_0_SUBNET} via ${WORKER_0_IP}
EOF
```

## Verification 

```bash
ssh -i /kthwLab/ssh/id_rsa root@server-0 ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160 
10.200.0.0/24 via XXX.XXX.XXX.XXX dev ens160 
10.200.1.0/24 via XXX.XXX.XXX.XXX dev ens160 
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX 
```

```bash
ssh -i /kthwLab/ssh/id_rsa root@worker-0 ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160 
10.200.1.0/24 via XXX.XXX.XXX.XXX dev ens160 
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX 
```

```bash
ssh -i /kthwLab/ssh/id_rsa root@worker-1 ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160 
10.200.0.0/24 via XXX.XXX.XXX.XXX dev ens160 
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX 
```


Next: [Smoke Test](12-smoke-test.md)
