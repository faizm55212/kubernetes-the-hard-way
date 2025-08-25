#!/bin/bash
set -e

cat <<'EOF' > /root/firstboot.sh
#!/bin/bash
set -e
exec > >(tee -a /var/log/firstboot.log) 2>&1

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

SSH_PUBKEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDfYgOpxDDSH8VPKNFXqM00TL1I1jxb0aibGWybwtniU/IA12DKiRfY/ynzIM1FJUzxrgLMRVc1xTFhC/lmOey0JbqDozTnkdnT7+B9MaoDpCOoTPo1EjmwF7POgZB9OvqliFrmm8ba+z42ZbTcgLLmo46SavlJthNwR4NUw4VMFKFlp5CEb7pxsU4cZXhFs3PYEUWhvgjTUwAWT5tHPlrJnzlJY0koKJizquMonYkYnCcQX7NPWSAlmgRxQWz0ym2eQes7X9nz49VxzHHp032wnBmmTB+R6jSsRXG1lE3fdJNIlUpIVLheHoSf/kuO+EVxhgtFc2QGafPMB1mqWGu4ZqtNzGXKNQBTstcqLjqgG5+0xMLafIDRgC/lo8vS3qnEu8tVnRlcdpP1Jw8XjdQbLwmiajYU38ozpFD+oT5xeQVae4pzUZKSdZUv95RITaI8jdqKEnAJ9AH7OAd6PPtLVotOSeCcdFZWGqmp6/zTZBP7XiU7MjpRe7J2GEp1yhc= root@unknown'

echo "[*] Setting hostname to $VM_NAME"
echo "$VM_NAME" > /etc/hostname
hostname "$VM_NAME"


echo "$VM_NAME" > /etc/hostname

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
