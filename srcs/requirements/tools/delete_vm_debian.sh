#!/bin/bash

set -e

# Debian VM Cleanup Script
echo "🗑️  Cleaning up Debian VM..."

### Configuration
VM_NAME="Debian-Inception"

# Directories and paths
ROOT_DIR="$(pwd)"
VMTOOLS_DIR="$ROOT_DIR/srcs/requirements/tools"

GOINFRE_DIR="/goinfre/yjinnouc"
VM_DIR="$GOINFRE_DIR/VMs/$VM_NAME"
VM_PATH="$VM_DIR/$VM_NAME.vdi"


### Stop VM
echo "📋 Stopping VM..."
if vboxmanage list runningvms | grep -q "$VM_NAME"; then
    echo "   Stopping VM '$VM_NAME'..."
    vboxmanage controlvm "$VM_NAME" poweroff 2>/dev/null || true
    sleep 5

    # Wait for VM to fully stop
    while vboxmanage list runningvms | grep -q "$VM_NAME"; do
        echo "   Waiting for VM to stop..."
        sleep 2
    done
    echo "   ✅ VM stopped"
else
    echo "   ✅ VM not running"
fi

### Remove VM
echo "📋 Removing VM..."
if vboxmanage list vms | grep -q "$VM_NAME"; then
    echo "   Removing VM '$VM_NAME'..."
    vboxmanage unregistervm "$VM_NAME" --delete 2>/dev/null || true
    echo "   ✅ VM removed"
else
    echo "   ✅ VM not found"
fi

### Clean up files
echo "📋 Cleaning up files..."
# Remove VDI file
if [ -f "$VM_PATH" ]; then
    echo "   Removing VDI file: $VM_PATH"
    rm -f "$VM_PATH"
    echo "   ✅ VDI file removed"
fi
# Remove VM directory
if [ -d "$VM_DIR" ]; then
    echo "   Removing VM directory: $VM_DIR"
    rmdir "$VM_DIR" 2>/dev/null || true
    echo "   ✅ VM directory cleaned"
fi
# Clean up generated preseed file
PRESEED_GENERATED="$VMTOOLS_DIR/preseed.cfg"
if [ -f "$PRESEED_GENERATED" ]; then
    echo "   Removing generated preseed file..."
    rm -f "$PRESEED_GENERATED"
    echo "   ✅ Preseed file removed"
fi

### Stop HTTP server
echo "📋 Stopping HTTP server..."
if lsof -ti:8001 >/dev/null 2>&1; then
    echo "   Stopping HTTP server on port 8001..."
    kill $(lsof -ti:8001) 2>/dev/null || true
    sleep 2
    echo "   ✅ HTTP server stopped"
else
    echo "   ✅ HTTP server not running"
fi

echo "🎉 Cleanup Complete!"
