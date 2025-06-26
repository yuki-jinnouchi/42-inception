#!/bin/bash

set -e

# Optimize VirtualBox VM for GUI Environment
echo "🖥️  Optimizing VirtualBox VM for GUI..."

VM_NAME="Debian-Inception"

# Check if VM exists
if ! VBoxManage list vms | grep -q "$VM_NAME"; then
    echo "❌ VM '$VM_NAME' not found"
    exit 1
fi

# Check if VM is running
if VBoxManage list runningvms | grep -q "$VM_NAME"; then
    echo "🔄 Stopping VM to apply GUI optimizations..."
    VBoxManage controlvm "$VM_NAME" poweroff
    sleep 5
fi

echo "⚙️  Applying GUI optimizations..."

# Optimize graphics settings for GUI
VBoxManage modifyvm "$VM_NAME" \
    --vram 128 \
    --accelerate3d on \
    --accelerate2dvideo on \
    --graphicscontroller vmsvga \
    --clipboard bidirectional \
    --draganddrop bidirectional \
    --audio pulse \
    --audiocontroller hda

echo "   ✅ Graphics optimizations applied:"
echo "      VRAM: 128MB"
echo "      3D Acceleration: Enabled"
echo "      2D Video Acceleration: Enabled"
echo "      Graphics Controller: VMSVGA"
echo "      Clipboard: Bidirectional"
echo "      Drag & Drop: Bidirectional"
echo "      Audio: PulseAudio"

# Restart VM
echo ""
echo "🔄 Starting optimized VM..."
VBoxManage startvm "$VM_NAME"

echo ""
echo "✅ GUI optimization complete!"
echo "VM is now optimized for desktop environment."
