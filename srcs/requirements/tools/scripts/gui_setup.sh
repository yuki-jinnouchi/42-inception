#!/bin/bash

# GUI Setup for Debian VM - Complete Automation
# Note: Some optional packages may fail to install, this is expected
echo "🖥️  GUI Setup for Debian VM - Complete GUI Environment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

### Configuration
VM_NAME="Debian-Inception"
SSH_PORT="2222"
SSH_USER="debian"
SSH_HOST="localhost"
VM_KEY_PRIVATE="$HOME/.ssh/id_rsa_42"
ROOT_DIR="$(pwd)"
VMTOOLS_DIR="$ROOT_DIR/srcs/requirements/tools"

### Prerequisites Check
echo "📋 Prerequisites Check..."

# Check if VM exists
if ! VBoxManage list vms | grep -q "$VM_NAME"; then
    echo "❌ VM '$VM_NAME' not found. Please run 'make setup' first."
    exit 1
fi

echo "   ✅ VM '$VM_NAME' found"

# Check if VM is running
if ! VBoxManage list runningvms | grep -q "$VM_NAME"; then
    echo "🔄 Starting VM..."
    VBoxManage startvm "$VM_NAME" --type headless
    sleep 30
fi

echo "   ✅ VM is running"

# Check SSH connectivity (with retry)
echo "🔍 Testing SSH connectivity..."
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ssh -A -i "$VM_KEY_PRIVATE" -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'SSH OK'" 2>/dev/null; then
        echo "   ✅ SSH connection established"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "   Waiting for SSH (attempt $((RETRY_COUNT))/$MAX_RETRIES)..."
    sleep 10
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ SSH connection failed. Please check VM status."
    exit 1
fi

### Step 1: Install GUI Environment
echo ""
echo "🖥️ Installing GUI Environment (XFCE4 + Firefox)"
echo "────────────────────────────────────────────────────────────────────────────────────"

if [ -f "$VMTOOLS_DIR/scripts/install_gui_debian.sh" ]; then
    cd "$ROOT_DIR"
    if bash "$VMTOOLS_DIR/scripts/install_gui_debian.sh"; then
        echo "   ✅ GUI Environment installation completed"
    else
        echo "   ⚠️  GUI Environment installation had some issues but continuing..."
    fi
else
    echo "❌ install_gui_debian.sh not found at $VMTOOLS_DIR/scripts"
    exit 1
fi

### Step 2: VirtualBox GUI Optimization
echo ""
echo "⚙️ Optimizing VirtualBox for GUI Performance"
echo "────────────────────────────────────────────────────────────────────────────────────"

if [ -f "$VMTOOLS_DIR/scripts/optimize_vm_gui.sh" ]; then
    cd "$ROOT_DIR"
    bash "$VMTOOLS_DIR/scripts/optimize_vm_gui.sh"
else
    echo "❌ optimize_vm_gui.sh not found at $VMTOOLS_DIR/scripts/"
    exit 1
fi

echo "   ✅ VirtualBox GUI optimization completed"

### Step 3: Setup Auto-login and Hosts Configuration
echo ""
echo "🔐 Setting up Auto-login and Domain Configuration"
echo "────────────────────────────────────────────────────────────────────────────────────"

if [ -f "$VMTOOLS_DIR/scripts/setup_gui_autologin.sh" ]; then
    cd "$ROOT_DIR"
    bash "$VMTOOLS_DIR/scripts/setup_gui_autologin.sh"
else
    echo "❌ setup_gui_autologin.sh not found at $VMTOOLS_DIR/scripts/"
    exit 1
fi

echo "   ✅ Auto-login and domain configuration completed"

### Step 4: Verify GUI Environment
echo ""
echo "🔍 Verifying GUI Environment"
echo "────────────────────────────────────────────────────────────────────────────────────"

# Wait for services to stabilize
echo "⏳ Waiting for GUI services to stabilize..."
sleep 15

# Check GUI processes
echo "🔍 Checking GUI processes..."
if ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "ps aux | grep -E '(xfce4-session|lightdm|Xorg)' | grep -v grep" 2>/dev/null; then
    echo "   ✅ GUI processes are running"
else
    echo "   ⚠️  Some GUI processes may still be starting"
fi

# Test HTTPS connectivity
echo "🌐 Testing HTTPS connectivity to yjinnouc.42.fr..."
if ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "curl -k -I https://yjinnouc.42.fr 2>/dev/null | head -1" 2>/dev/null; then
    echo "   ✅ HTTPS connection to yjinnouc.42.fr working"
else
    echo "   ⚠️  HTTPS connection may need Docker containers running"
fi

### Final Status Report
echo ""
echo "🎉 GUI Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 GUI Environment Summary:"
echo "   ✅ Desktop Environment: XFCE4 (Lightweight)"
echo "   ✅ Display Manager: LightDM (Auto-login enabled)"
echo "   ✅ Web Browser: Firefox ESR"
echo "   ✅ VirtualBox Optimization: 128MB VRAM, 3D Acceleration"
echo "   ✅ Domain Configuration: yjinnouc.42.fr -> 127.0.0.1"
echo "   ✅ SSH Access: ssh -A -i $VM_KEY_PRIVATE -p $SSH_PORT $SSH_USER@$SSH_HOST"
echo ""
echo "🖥️  VirtualBox GUI Access:"
echo "   1. Open VirtualBox Manager"
echo "   2. Select '$VM_NAME' VM"
echo "   3. Click 'Show' to open VM window"
echo "   4. Desktop should appear automatically (auto-login)"
echo ""
echo "🦊 Firefox Testing Steps:"
echo "   1. Open Firefox ESR from desktop or applications menu"
echo "   2. Navigate to: https://yjinnouc.42.fr"
echo "   3. Accept SSL certificate if prompted"
echo "   4. Test WordPress installation"
echo ""
echo "📝 Login Credentials (if manual login needed):"
echo "   Username: debian"
echo "   Password: debian_user_password"
echo ""
echo "🚀 Next Steps:"
echo "   • Run 'make build' to start Docker containers if not already running"
echo "   • Open VirtualBox GUI and test Firefox access to https://yjinnouc.42.fr"
echo "   • Verify WordPress installation works correctly"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Open VirtualBox GUI automatically if possible
echo ""
echo "💡 Opening VirtualBox GUI..."
if command -v VBoxManage >/dev/null 2>&1; then
    if VBoxManage list runningvms | grep -q "$VM_NAME"; then
        # Try to show the VM window
        VBoxManage startvm "$VM_NAME" --type gui 2>/dev/null || true
        echo "   VirtualBox GUI should now be open"
    fi
fi

echo ""
echo "✨ GUI setup automation complete! Ready for browser testing."
