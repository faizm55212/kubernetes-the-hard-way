#!/bin/bash
set -e

cat <<'EOF' > /root/firstboot.sh
#!/bin/bash
set -e

VM_NAME="${1}"

declare -A FQDN_MAP
FQDN_MAP=(
  [server-0]="server-0.kubernetes.local"
  [worker-0]="worker-0.kubernetes.local"
  [worker-1]="worker-1.kubernetes.local"
)

STATIC_HOSTS=$(cat <<EOT
127.0.0.1 localhost
192.168.122.16 server-0.kubernetes.local server-0
192.168.122.17 worker-0.kubernetes.local worker-0
192.168.122.18 worker-1.kubernetes.local worker-1
EOT
)

SSH_PUBKEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxE9L5tUcV/ftZ21z/15ry8FejVaQ18+4UkoMvZN/0zuGT5Olthroh8En6EGtOsYZAMUs0IyISQnd4g7lO8+LalKJkWIteKgKOMYP8UQ8WWyb6q2PtC9g7KWPwVdgYoVi1iKm/jr65UhzMTv1g+emxiar7ZMNMK/dT+22lYi7BaTxBHC+nFX39HRv7lWWbEhgi7yJkzck721n3RWrk1NP/ta1qAQnh94AMxD1neZPSrRd8CX4HyHPyhBWnePtj84hkI+eBDoBaSno2+rUAiIaae9wY+Z9zS26ry0Tm/kks4qvhSenKqcLL4ajuolmpJnWlxAKCG/HEpEnF4TIQLb8v/WbGSbQX9Uq+/7WZFApwYmjd+ph3HUoQERSK3rmtpIPUdjb05xJwX3ypEn1Fyk65IhcwPVT4bSJPKdVLGt7HRSmwzvXYuqNPS4MEjhwcoK/l9pUabvj9rs73/xlZjsef04E+w8sAa0rk6mhK+QoFd3JAtQhzJdSkUJuo5Y6YuNk= root@unknown-pc'

echo "[*] Setting hostname to $VM_NAME"
echo "$VM_NAME" > /etc/hostname
hostname "$VM_NAME"


echo "${FQDN_MAP[$VM_NAME]}" > /etc/hostname

echo "$STATIC_HOSTS" > /etc/hosts


echo "[*] Updating and installing packages"
apt update && apt -y upgrade
apt install -y openssh-server vim


echo "[*] Configuring SSH"
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "$SSH_PUBKEY" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

systemctl enable ssh
systemctl restart ssh

# Only run once
rm -f /etc/systemd/system/firstboot.service
rm -f /root/firstboot.sh
EOF

chmod +x /root/firstboot.sh

# Create systemd unit
cat <<EOF > /etc/systemd/system/firstboot.service
[Unit]
Description=Run first boot script
After=network.target

[Service]
Type=oneshot
ExecStart=/root/firstboot.sh "${1}"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable firstboot.service
