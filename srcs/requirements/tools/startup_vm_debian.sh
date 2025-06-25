#!/bin/bash

set -e

# Debian VM Setup
echo "🚀 Setting up Debian VM with ISO Remastering (ZERO manual intervention)..."

### Configuration
# Directories and paths
VM_NAME="Debian-Inception"

ROOT_DIR="$(pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"
VMTOOLS_DIR="$ROOT_DIR/srcs/requirements/tools"

PRESEED_TEMPLATE="$VMTOOLS_DIR/conf/preseed_template.cfg"
ISOLINUX_TEMPLATE="$VMTOOLS_DIR/conf/isolinux_template.cfg"

GOINFRE_DIR="/goinfre/yjinnouc"
VM_DIR="$GOINFRE_DIR/VMs/$VM_NAME"
VM_PATH="$VM_DIR/$VM_NAME.vdi"

ORIGINAL_ISO="$GOINFRE_DIR/debian-11.11.0-amd64-DVD-1.iso"
CUSTOM_ISO="$GOINFRE_DIR/debian-11.11.0-amd64-DVD-1-auto.iso"
# Use DVD ISO for faster offline installation (Debian 11 Bullseye - penultimate stable version)
ISO_URL="https://cdimage.debian.org/cdimage/archive/11.11.0/amd64/iso-dvd/debian-11.11.0-amd64-DVD-1.iso"


### Password Setup
echo "📋 Setting up credentials..."
if [ ! -s "$SECRETS_DIR/debian_password.txt" ]; then
    echo "   Generating Debian password..."
    openssl rand -base64 12 > "$SECRETS_DIR/debian_password.txt"
fi
DEBIAN_PASSWORD=$(cat "$SECRETS_DIR/debian_password.txt")
echo "   ✅ Password ready: $DEBIAN_PASSWORD"


### Download Original ISO
echo "📋 Preparing original Debian ISO..."
if [ ! -f "$ORIGINAL_ISO" ]; then
    echo "   Downloading Debian 11 DVD ISO (penultimate stable version)..."
    wget -c --progress=bar "$ISO_URL" -O "$ORIGINAL_ISO"
    echo "   ✅ ISO downloaded"
else
    echo "   ✅ Original ISO already exists"
fi


### Create Custom ISO with Embedded Preseed
echo "📋 Creating custom ISO with embedded preseed..."
# Check if custom ISO needs to be rebuilt
REBUILD_ISO=false

if [ ! -f "$CUSTOM_ISO" ]; then
    echo "   Custom ISO not found, will create new one"
    REBUILD_ISO=true
else
    echo "   Checking if custom ISO needs rebuild..."

    # Check each dependency file individually
    if [ ! -f "$PRESEED_TEMPLATE" ]; then
        echo "   ❌ Dependency missing: $(basename "$PRESEED_TEMPLATE")"
        exit 1
    elif [ "$PRESEED_TEMPLATE" -nt "$CUSTOM_ISO" ]; then
        echo "   Dependency changed: $(basename "$PRESEED_TEMPLATE")"
        REBUILD_ISO=true
    elif [ ! -f "$ISOLINUX_TEMPLATE" ]; then
        echo "   ❌ Dependency missing: $(basename "$ISOLINUX_TEMPLATE")"
        exit 1
    elif [ "$ISOLINUX_TEMPLATE" -nt "$CUSTOM_ISO" ]; then
        echo "   Dependency changed: $(basename "$ISOLINUX_TEMPLATE")"
        REBUILD_ISO=true
    elif [ ! -f "$SECRETS_DIR/debian_password.txt" ]; then
        echo "   ❌ Dependency missing: $(basename "$SECRETS_DIR/debian_password.txt")"
        exit 1
    elif [ "$SECRETS_DIR/debian_password.txt" -nt "$CUSTOM_ISO" ]; then
        echo "   Dependency changed: $(basename "$SECRETS_DIR/debian_password.txt")"
        REBUILD_ISO=true
    elif [ ! -f "$ORIGINAL_ISO" ]; then
        echo "   ❌ Dependency missing: $(basename "$ORIGINAL_ISO")"
        exit 1
    elif [ "$ORIGINAL_ISO" -nt "$CUSTOM_ISO" ]; then
        echo "   Dependency changed: $(basename "$ORIGINAL_ISO")"
        REBUILD_ISO=true
    fi
fi

if [ "$REBUILD_ISO" = "false" ]; then
    echo "   ✅ Custom ISO is up to date, skipping rebuild"
else
    # Call external ISO creation script
    WORK_DIR="$GOINFRE_DIR/iso_work"
    if ! "$VMTOOLS_DIR/create_custom_iso.sh" \
        "$ORIGINAL_ISO" "$CUSTOM_ISO" "$PRESEED_TEMPLATE" \
        "$ISOLINUX_TEMPLATE" "$DEBIAN_PASSWORD" "$WORK_DIR"; then
        echo "   ❌ Error: Failed to create custom ISO"
        exit 1
    fi
fi


### VM Setup
echo "📋 Setting up VirtualBox VM..."

# Remove existing VM if present
if vboxmanage list vms | grep -q "$VM_NAME"; then
    echo "   Removing existing VM..."
    if vboxmanage list runningvms | grep -q "$VM_NAME"; then
        vboxmanage controlvm "$VM_NAME" poweroff 2>/dev/null || true
        sleep 3
    fi
    vboxmanage unregistervm "$VM_NAME" --delete 2>/dev/null || true
fi

# Clean up VDI files
[ -f "$VM_PATH" ] && rm -f "$VM_PATH"
mkdir -p "$VM_DIR"

# Create new VM
echo "   Creating VM '$VM_NAME'..."
vboxmanage createvm --name "$VM_NAME" --ostype "Debian_64" --register
vboxmanage modifyvm "$VM_NAME" \
    --memory 12288 \
    --cpus 4 \
    --vram 128 \
    --accelerate3d off \
    --boot1 dvd --boot2 disk --boot3 none --boot4 none \
    --nic1 nat \
    --natpf1 "ssh,tcp,,2222,,22" \
    --natpf1 "http,tcp,,8080,,80" \
    --natpf1 "https,tcp,,8443,,443" \
    --rtcuseutc on \
    --ioapic on \
    --pae on \
    --largepages on \
    --vtxvpid on \
    --vtxux on \
    --nestedpaging on \
    --firmware bios

# Create storage with optimized settings
echo "   Setting up storage..."
vboxmanage createhd --filename "$VM_PATH" --size 10240 --format VDI --variant Standard
vboxmanage storagectl "$VM_NAME" --name "SATA Controller" --add sata --portcount 2 --hostiocache on --bootable on
vboxmanage storageattach "$VM_NAME" --storagectl "SATA Controller" \
    --port 0 --device 0 --type hdd --medium "$VM_PATH" --nonrotational on --discard on
vboxmanage storagectl "$VM_NAME" --name "IDE Controller" --add ide
vboxmanage storageattach "$VM_NAME" --storagectl "IDE Controller" \
    --port 0 --device 0 --type dvddrive --medium "$CUSTOM_ISO"

echo "   ✅ VM created successfully"


### Start VM
echo "📋 Starting VM..."
vboxmanage startvm "$VM_NAME"
# Wait a moment for VM to start properly
sleep 2
# Call the VM status script to display current information
sh "$VMTOOLS_DIR/print_vm_status.sh" "$VM_NAME"
echo "   ✅ VM started successfully"
