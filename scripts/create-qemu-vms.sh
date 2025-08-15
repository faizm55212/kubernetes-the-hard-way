#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration Variables ---
BASE_DIR="/kthwLab"
DEBIAN_IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/20250814-2204/debian-13-nocloud-amd64-20250814-2204.qcow2"
DEBIAN_IMAGE_FILE="debian-13-nocloud-amd64-20250814-2204.qcow2"
VM_DISK_SIZE="20G"
VIRT_MEM=2048
VIRT_CPUS=2
USER_NAME=${SUDO_USER:-$(whoami)}

# VM configuration data in associative arrays
declare -A VM_IPS=(
  [server-0]="192.168.122.16"
  [worker-0]="192.168.122.17"
  [worker-1]="192.168.122.18"
)

declare -A VM_MACS=(
  [server-0]="52:54:00:42:c7:48"
  [worker-0]="52:54:00:42:c8:49"
  [worker-1]="52:54:00:42:c9:50"
)

# List of VMs to create
VMS=("server-0" "worker-0" "worker-1")

# --- Function to check for required commands ---
check_dependencies() {
  local required_commands=("mkdir" "wget" "qemu-img" "virt-customize" "virt-install" "tee" "curl" "openssl")
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "Error: Required command '$cmd' not found. Please install it."
      exit 1
    fi
  done
}

# --- Main Script ---

echo "--- Starting VM creation process ---"

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

check_dependencies

# 1. Create base directories
echo "Creating base directories..."
mkdir -p "$BASE_DIR/debian-image"
for vm in "${VMS[@]}"; do
  mkdir -p "$BASE_DIR/vms/$vm-files"
done

# 2. Create the SSH key pair non-interactively

if [ ! -f "$BASE_DIR/ssh/id_rsa" ]; then
  echo "Creating SSH key pair..."
  mkdir -p "$BASE_DIR/ssh"
  ssh-keygen -t rsa -f "$BASE_DIR/ssh/id_rsa" -N "" -q
else
  echo "SSH key pair already exists at $BASE_DIR/ssh/id_rsa"
fi
# Read the public key into a variable
SSH_PUBKEY=$(cat "$BASE_DIR/ssh/id_rsa.pub")

# 3. Use `sed` to update the starter script with the public key
echo "Updating starter-script.sh with the new public key..."
# Note: You must have a starter-script.sh file with a placeholder
sed -i "s|SSH_PUBKEY='.*'|SSH_PUBKEY='$SSH_PUBKEY'|" "$BASE_DIR/kubernetes-the-hard-way/scripts/starter-script.sh"

# 4. Download the Debian cloud image
if [ ! -f "$BASE_DIR/debian-image/$DEBIAN_IMAGE_FILE" ]; then
  echo "Downloading Debian cloud image..."
  wget -P "$BASE_DIR/debian-image" "$DEBIAN_IMAGE_URL"
else
  echo "Debian cloud image already exists at $DEBIAN_IMAGE_PATH"
fi

# 5. Loop through and create/customize VMs
echo "Creating and customizing VM disk images..."
for vm in "${VMS[@]}"; do
  echo "--- Processing $vm ---"

  VM_DISK_PATH="$BASE_DIR/vms/$vm-files/$vm.qcow2"
  BASE_IMAGE="$BASE_DIR/debian-image/$DEBIAN_IMAGE_FILE"

  # Create disk images with base image
  qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$VM_DISK_PATH" "$VM_DISK_SIZE"

  # Customize the VM with the starter script
  virt-customize \
    -a "$VM_DISK_PATH" \
    --upload "$BASE_DIR/kubernetes-the-hard-way/scripts/starter-script.sh:/root/vm-setup.sh" \
    --run-command "chmod +x /root/vm-setup.sh" \
    --run-command "/root/vm-setup.sh $vm" \
    --run-command "rm -f /root/vm-setup.sh"

done

# 6. Update libvirt default network with static DHCP host entries
echo "Updating libvirt network with static DHCP entries..."

# Backup current network XML
virsh net-dumpxml default > /tmp/default-net.xml.bak

if [ -f "/tmp/default-net.xml" ]; then
    rm -rf /tmp/default-net.xml
fi

# Build host entries dynamically from the associative arrays
cat /tmp/default-net.xml.bak | while IFS= read -r line; do
  if [[ "$line" =~ "</dhcp>" ]]; then
    for vm in "${VMS[@]}"; do
      echo "      <host mac='${VM_MACS[$vm]}' name='${vm}.kubernetes.local' ip='${VM_IPS[$vm]}'/>" >> /tmp/default-net.xml
    done
  fi
  echo "$line" >> /tmp/default-net.xml
done

# Redefine and restart the network
virsh net-destroy default
virsh net-undefine default
virsh net-define /tmp/default-net.xml
virsh net-start default
virsh net-autostart default

# 7. Install VMs using virt-install
echo "Installing VMs with virt-install..."
for vm in "${VMS[@]}"; do
  echo "--- Installing $vm ---"

  VM_DISK_PATH="$BASE_DIR/vms/$vm-files/$vm.qcow2"

  virt-install \
    --name "$vm" \
    --memory "$VIRT_MEM" \
    --vcpus "$VIRT_CPUS" \
    --disk path="$VM_DISK_PATH",format=qcow2 \
    --import \
    --os-variant debian13 \
    --network network=default,mac="${VM_MACS[$vm]}" \
    --noautoconsole
done

# 8. Append host entries to /etc/hosts
echo "Appending host entries to /etc/hosts..."
tee -a /etc/hosts <<EOF
${VM_IPS[server-0]} server-0.kubernetes.local server-0
${VM_IPS[worker-0]} worker-0.kubernetes.local worker-0
${VM_IPS[worker-1]} worker-1.kubernetes.local worker-1
EOF

# 9. Append host entries to /etc/hosts
echo "Creating machines.txt..."
rm $BASE_DIR/machines.txt
tee -a $BASE_DIR/machines.txt <<EOF
${VM_IPS[server-0]} server-0.kubernetes.local server-0 10.200.0.0/24
${VM_IPS[worker-0]} worker-0.kubernetes.local worker-0 10.200.1.0/24
${VM_IPS[worker-1]} worker-1.kubernetes.local worker-1 10.200.2.0/24
EOF

# 10. Fixing ownership and permissions for user 

chown -R "$USER_NAME":"$USER_NAME" "$BASE_DIR"

echo "--- VM creation process complete! ---"
echo "VMs should now be running. You can check their status with 'virsh list --all'."
