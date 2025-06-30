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
if [ -f "$SECRETS_DIR/debian_user_password.txt" ]; then
    DEBIAN_USER_PASSWORD=$(cat "$SECRETS_DIR/debian_user_password.txt")
else
    DEBIAN_USER_PASSWORD="(not available)"
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
echo ""
echo "🔐 Login Credentials:"
echo "   Username: debian"
echo "   Password: $DEBIAN_USER_PASSWORD"
echo ""
echo "🌐 Network Access (after installation):"
echo "   SSH: ssh -p 2222 debian@localhost"
echo "   HTTP: http://localhost:8080"
echo "   HTTPS: https://localhost:8443"
echo ""

if [ "$VM_STATE" = "running" ]; then
    echo "🚀 VM Status: RUNNING"
    echo "   ✅ VM is currently active"

    # Test SSH connectivity
    echo "   🔍 Testing SSH connectivity..."
    if timeout 5 nc -z localhost 2222 2>/dev/null; then
        echo "   ✅ SSH port 2222 is accessible"

        # Test SSH configuration
        SSH_TEST=$(timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 2222 debian@localhost "echo 'SSH_OK'" 2>/dev/null || echo "FAILED")
        if [ "$SSH_TEST" = "SSH_OK" ]; then
            echo "   ✅ SSH connection successful"

            # Check SSH service status
            SSH_SERVICE=$(timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 2222 debian@localhost "systemctl is-active ssh" 2>/dev/null || echo "unknown")
            echo "   📡 SSH service status: $SSH_SERVICE"

            # Check SSH configuration
            SSH_CONFIG=$(timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 2222 debian@localhost "grep -E '^(Port|PasswordAuthentication|PubkeyAuthentication)' /etc/ssh/sshd_config 2>/dev/null | tr '\n' ' '" 2>/dev/null || echo "config check failed")
            if [ "$SSH_CONFIG" != "config check failed" ]; then
                echo "   ⚙️  SSH config: $SSH_CONFIG"
            fi
        else
            echo "   ⚠️  SSH connection failed (installation may still be in progress)"
        fi
    else
        echo "   ⚠️  SSH port not yet accessible (installation in progress)"
    fi

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
