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

SSH_PUBKEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/AKeijOTE1ZKKkbG6q/MVx4OmqkUC2f2416H0QcDdZaX0ee6wPFah/EuPw3zrQL0AUwXZE2x2WlAUoHJYgeqKGKSGBI6erF3aNvydEIGr/XDsuespLlN04M/hE4D6hNhWBo9Vd6MrvVw+4B6ELE6344NhDYkLkzy7q98M3dRWbyH1aaZg6gsUMxRS405jvLYmkzSr8PE/U3J5rhQ+UDJMFdbr+pV0f5GV/4Q+xKZ9O3Ax+jcHA0DCWz9W03t/lSx9JG/m/bzuGcyWs2068lYdKla12gmXXAPitIcyQ8+zjdtYIJXfABkr7QJArXqk8egpVaiRspVs2XzeIGK6RmTG17nbdnvAXxfOqOIuTp3ko6Zc1BCLwqWj93euMeONy05GIL3oxhASUfg2V86SShHKK/QYqts9sKUW3LrxGbgYXIE7MfRA/121cuxTJA3YU0+5ElfJWLIn4MZ6HTEf3/8ss77c5dje9jWJ1CqPENxn0Ub4pz/bfaiZo/eiI8kc+vE= root@unknown-pc'

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
