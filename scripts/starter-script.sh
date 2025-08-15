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

SSH_PUBKEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtVm2B684Vx7FaRjgq8aNACRAg0UyfuKKmbBVx0AmZR7TTNEtCl3yA72hEQ2q0jRAr2m4kOprmMS48f0Ic9SPPSbp1zZCHDfcUMG9E1yiCX5uQIveXuGGiWniAE2EuttlYBd0Ij/FGeE4eLpmescAP6pDqJfbeeN2eFoJgA+tfaijCTeq9SryaOCViuCSk8ymNli6MNMD/3DAkEL8QLYeR9xsbfVr/3q50nNJvR5LlUmvlp/a1ufniFe1HN02aPI0/4W/N0bmEKUSZRadsTzI5Tl3I6376bf3UpwQJYZkLn+BKWcpkOECmEYnQuJycnvwZkz95j6Gu8dIzl039P0r+jTZEje8OQpN1XtxM4ff6WslqWfC1BigiTgIGP1NnoQ7ZD9R68Sw7+MDGXp44ByovF9SaVnuoY2371y0DKd+61MH/e+Uzn1crzWBK9oN+zZTRIoJU+Waq8dbajVI94yXlwFaoqWV77BhKUgCwhgsFra2m9EOlFFBSsKggfQUhon8= root@unknown-pc'

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

sed -i 's/^\(session\s\+optional\s\+pam_motd\.so.*\)/#\1/' /etc/pam.d/sshd

if ! grep -q '^PrintLastLog no' /etc/ssh/sshd_config; then
  echo "PrintLastLog no" >> /etc/ssh/sshd_config
fi

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
