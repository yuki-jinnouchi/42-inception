#!/bin/bash

# VM Status Display Script

# Usage: print_vm_status.sh <VM_NAME>
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <VM_NAME>"
    exit 1
fi

VM_NAME="$1"

# Check if VM exists
if ! vboxmanage list vms | grep -q "\"$VM_NAME\""; then
    echo "❌ VM '$VM_NAME' not found"
    exit 1
fi

# Get VM information from VirtualBox
VM_MEMORY=$(vboxmanage showvminfo "$VM_NAME" --machinereadable | grep "^memory=" | cut -d'=' -f2)
VM_CPUS=$(vboxmanage showvminfo "$VM_NAME" --machinereadable | grep "^cpus=" | cut -d'=' -f2)
VM_STATE=$(vboxmanage showvminfo "$VM_NAME" --machinereadable | grep "^VMState=" | cut -d'=' -f2 | tr -d '"')
VM_OSTYPE=$(vboxmanage showvminfo "$VM_NAME" --machinereadable | grep "^ostype=" | cut -d'=' -f2 | tr -d '"')

# Get password if available
ROOT_DIR="$(pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"
if [ -f "$SECRETS_DIR/debian_password.txt" ]; then
    DEBIAN_PASSWORD=$(cat "$SECRETS_DIR/debian_password.txt")
else
    DEBIAN_PASSWORD="(not available)"
fi

# Determine state icon and color
case "$VM_STATE" in
    "running")
        STATE_ICON="🟢"
        STATE_TEXT="Running"
        ;;
    "poweroff")
        STATE_ICON="🔴"
        STATE_TEXT="Powered Off"
        ;;
    "paused")
        STATE_ICON="🟡"
        STATE_TEXT="Paused"
        ;;
    "saved")
        STATE_ICON="🟠"
        STATE_TEXT="Saved"
        ;;
    *)
        STATE_ICON="⚪"
        STATE_TEXT="$VM_STATE"
        ;;
esac

echo ""
echo "🎉 Debian VM Status Report!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VM Information:"
echo "   VM Name: $VM_NAME"
echo "   Memory: ${VM_MEMORY}MB ($(( VM_MEMORY / 1024 ))GB) RAM"
echo "   CPU: $VM_CPUS cores"
echo "   OS Type: $VM_OSTYPE"
echo "   State: $STATE_ICON $STATE_TEXT"
echo "   Storage: 10GB (optimized)"
echo "   OS: Debian 11 (Bullseye) - penultimate stable version"
echo "   ISO: DVD Auto-Install (MINIMAL PACKAGES)"
echo ""
echo "🔐 Login Credentials:"
echo "   Username: debian"
echo "   Password: $DEBIAN_PASSWORD"
echo ""
echo "🌐 Network Access (after installation):"
echo "   SSH: ssh -p 2222 debian@localhost"
echo "   HTTP: http://localhost:8080"
echo "   HTTPS: https://localhost:8443"
echo ""

if [ "$VM_STATE" = "running" ]; then
    echo "🚀 VM Status: RUNNING"
    echo "   ✅ VM is currently active"
    echo "   ✅ Ready for SSH access (if installation complete)"
    echo "   ✅ Monitor progress in VirtualBox GUI"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Wait for installation to complete (~3 minutes)"
    echo "   2. Test SSH connection: ssh -p 2222 debian@localhost"
    echo "   3. Install Docker and Docker Compose"
    echo "   4. Deploy WordPress/Nginx containers"
elif [ "$VM_STATE" = "poweroff" ]; then
    echo "🔴 VM Status: POWERED OFF"
    echo "   ℹ️  VM is not running"
    echo "   💡 Start with: vboxmanage startvm \"$VM_NAME\""
    echo ""
    echo "📝 To start VM:"
    echo "   1. Run: make vm_setup (for fresh setup)"
    echo "   2. Or: vboxmanage startvm \"$VM_NAME\" (existing VM)"
else
    echo "⚪ VM Status: $STATE_TEXT"
    echo "   ℹ️  VM is in $STATE_TEXT state"
    echo "   💡 Check VirtualBox GUI for details"
fi

echo ""
echo "⏱️  Installation time: ~3 minutes (much faster with DVD + 12GB RAM!)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
