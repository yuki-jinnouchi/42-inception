#!/bin/bash

set -e

# Setup Virtual Machine to run Docker
echo "Setting up Virtual Machine for Ubuntu Inception..."

# Exit if VirtualBox is not installed
if vboxmanage list vms | grep -q "Ubuntu-Inception"; then
    echo "VM 'Ubuntu-Inception' already exists. Checking health..."
    if vboxmanage showvminfo "Ubuntu-Inception" | grep -q "State: running"; then
        echo "VM is already running. Exiting setup."
        exit 0
    else
        echo "VM exists but is not running. Proceeding with setup."
    fi
fi

ROOT_DIR="$(pwd)"
VMTOOLS_DIR="$ROOT_DIR/srcs/requirements/tools"
GOINFRE_DIR="/goinfre/yjinnouc"
ISO_URL="https://releases.ubuntu.com/jammy/ubuntu-22.04.5-live-server-amd64.iso"
ISO_DIR="$GOINFRE_DIR/ubuntu-22.04.5-live-server-amd64.iso"
VM_DIR="$GOINFRE_DIR/VMs/Ubuntu-Inception"
VM_PATH="$VM_DIR/Ubuntu-Inception.vdi"
PRESEED_TEMPLATE="$VMTOOLS_DIR/preseed.cfg"
PRESEED_FILE="$VMTOOLS_DIR/preseed_generated.cfg"
SECRETS_DIR="$ROOT_DIR/secrets"

# Generate or read Ubuntu password from secrets
if [ ! -s "$SECRETS_DIR/ubuntu_password.txt" ]; then
    echo "Generating Ubuntu password..."
    openssl rand -base64 12 > "$SECRETS_DIR/ubuntu_password.txt"
fi
UBUNTU_PASSWORD=$(cat "$SECRETS_DIR/ubuntu_password.txt")

echo "Creating preseed file with secrets..."
# Create preseed file with password from secrets
sed "s/UBUNTU_PASSWORD_PLACEHOLDER/$UBUNTU_PASSWORD/g" "$PRESEED_TEMPLATE" > "$PRESEED_FILE"

# get the Ubuntu Server ISO (skip if already exists and complete)
echo "Checking Ubuntu ISO..."
wget -c -N --progress=bar "$ISO_URL" -O "$ISO_DIR"

# Check if VM already exists and remove it
echo "Checking for existing VM..."
if vboxmanage list vms | grep -q "Ubuntu-Inception"; then
    echo "VM 'Ubuntu-Inception' already exists. Removing it..."
    # Stop VM if running
    if vboxmanage list runningvms | grep -q "Ubuntu-Inception"; then
        vboxmanage controlvm "Ubuntu-Inception" poweroff
    fi
    # Remove VM completely
    vboxmanage unregistervm "Ubuntu-Inception" --delete
fi

# Clean up any existing VDI files
echo "Cleaning up existing VDI files..."
if [ -f "$VM_PATH" ]; then
    echo "Removing existing VDI file: $VM_PATH"
    rm -f "$VM_PATH"
fi

# Create VM with automated installation support
echo "Creating VM 'Ubuntu-Inception'..."
vboxmanage createvm --name "Ubuntu-Inception" --ostype "Ubuntu_64" --register
vboxmanage modifyvm "Ubuntu-Inception" --memory 4096
vboxmanage modifyvm "Ubuntu-Inception" --cpus 2
vboxmanage modifyvm "Ubuntu-Inception" --vram 128
vboxmanage modifyvm "Ubuntu-Inception" --accelerate3d off
vboxmanage modifyvm "Ubuntu-Inception" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Create Network
echo "Setting up network for VM..."
vboxmanage modifyvm "Ubuntu-Inception" --nic1 nat
vboxmanage modifyvm "Ubuntu-Inception" --natpf1 "ssh,tcp,,2222,,22"
vboxmanage modifyvm "Ubuntu-Inception" --natpf1 "http,tcp,,8080,,80"
vboxmanage modifyvm "Ubuntu-Inception" --natpf1 "https,tcp,,8443,,443"

# Create Directories
echo "Creating directories for VM..."
mkdir -p "$GOINFRE_DIR/VMs/Ubuntu-Inception"
vboxmanage createhd	--filename "$VM_PATH" --size 10240
vboxmanage storagectl "Ubuntu-Inception" --name "SATA Controller" --add sata
vboxmanage storageattach "Ubuntu-Inception" --storagectl "SATA Controller" \
	--port 0 --device 0 --type hdd --medium "$VM_PATH"
vboxmanage storagectl "Ubuntu-Inception" --name "IDE Controller" --add ide
vboxmanage storageattach "Ubuntu-Inception" --storagectl "IDE Controller" \
	--port 0 --device 0 --type dvddrive --medium "$ISO_DIR"

# Auto-installation setup using preseed via floppy disk
echo "Setting up automated installation using floppy disk..."
FLOPPY_IMG="$VM_DIR/preseed.img"

# Create floppy disk image
echo "Creating floppy disk image for preseed..."
dd if=/dev/zero of="$FLOPPY_IMG" bs=1024 count=1440
mkfs.fat -F 12 "$FLOPPY_IMG"

# Copy preseed file to floppy image using mtools (no mount required)
echo "Copying preseed file to floppy image..."
mcopy -i "$FLOPPY_IMG" "$PRESEED_FILE" ::preseed.cfg

# Attach floppy disk to VM
echo "Attaching floppy disk to VM..."
vboxmanage storagectl "Ubuntu-Inception" --name "Floppy Controller" --add floppy
vboxmanage storageattach "Ubuntu-Inception" --storagectl "Floppy Controller" \
	--port 0 --device 0 --type fdd --medium "$FLOPPY_IMG"

# Add kernel parameters for automated installation
echo "Configuring VM for automated installation..."
vboxmanage modifyvm "Ubuntu-Inception" \
	--rtcuseutc on

# Connect to the VM
echo "Starting VM 'Ubuntu-Inception'..."
echo "Preseed file is available at: /media/floppy0/preseed.cfg"
vboxmanage startvm "Ubuntu-Inception"
# vboxmanage startvm "Ubuntu-Inception" --type headless

echo "🔄 VM is starting up. For automated installation:"
echo "   1. When Ubuntu installer loads, press TAB at the boot menu"
echo "   2. Add this to the kernel parameters:"
echo "   file=/media/floppy0/preseed.cfg"
echo "   3. Press ENTER to start automated installation"
echo ""

# Check health of the VM
vboxmanage showvminfo "Ubuntu-Inception" | grep State
vboxmanage list runningvms

echo "🚀 VM Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VM Information:"
echo "   VM Name: Ubuntu-Inception"
echo "   Memory: 4GB"
echo "   Storage: 10GB"
echo "   OS: Ubuntu 22.04 Server"
echo ""
echo "🔐 Login Credentials:"
echo "   Username: ubuntu"
echo "   Password: $UBUNTU_PASSWORD"
echo ""
echo "🌐 Network Access:"
echo "   SSH: ssh -p 2222 ubuntu@localhost"
echo "   HTTP: http://localhost:8080"
echo "   HTTPS: https://localhost:8443"
echo ""
echo "📝 Notes:"
echo "   • Ubuntu will install automatically using preseed"
echo "   • Docker and Docker Compose will be installed"
echo "   • SSH server will be enabled"
echo "   • Installation usually takes 15-30 minutes"
echo "   • You can monitor progress through VirtualBox GUI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Optional: Clean up floppy image after installation completes
# rm -f "$FLOPPY_IMG"

# Shutdown the VM (commented out for normal operation)
# vboxmanage controlvm "Ubuntu-Inception" poweroff
# vboxmanage unregistervm "Ubuntu-Inception" --delete

# Pause and Resume the VM (for reference)
# vboxmanage controlvm "Ubuntu-Inception" pause
# vboxmanage controlvm "Ubuntu-Inception" resume
