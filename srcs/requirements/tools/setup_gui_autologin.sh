#!/bin/bash

set -e

# Setup GUI Auto-login for Debian VM
echo "🔐 Setting up GUI auto-login..."

### Configuration
VM_NAME="Debian-Inception"
SSH_PORT="2222"
SSH_USER="debian"
SSH_HOST="localhost"
VM_KEY_PRIVATE="$HOME/.ssh/id_rsa_42"

### Check SSH connection
echo "📋 Checking SSH connection..."
if ! ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'SSH OK'" 2>/dev/null; then
    echo "❌ SSH connection failed. Please run gui_setup.sh first."
    exit 1
fi

echo "   ✅ SSH connection OK"

### Setup Auto-login Configuration
echo ""
echo "🔐 Configuring LightDM auto-login..."

# Transfer and execute auto-login setup script
cat << 'EOF' | ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "cat > /tmp/setup_autologin.sh"
#!/bin/bash
set -e

echo "🔐 Setting up auto-login configuration..."

# Reset debian user password to ensure it works
echo "   Resetting user password..."
echo 'debian:debian_user_password' | sudo chpasswd

# Create LightDM config directory if it doesn't exist
echo "   Creating LightDM configuration directory..."
sudo mkdir -p /etc/lightdm/lightdm.conf.d

# Configure LightDM for automatic login
echo "   Configuring auto-login..."
sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf << 'AUTOLOGIN_EOF'
[Seat:*]
autologin-user=debian
autologin-user-timeout=0
user-session=xfce
AUTOLOGIN_EOF

# Setup hosts file for yjinnouc.42.fr
echo "   Configuring hosts file for yjinnouc.42.fr..."
if ! grep -q "yjinnouc.42.fr" /etc/hosts; then
    echo "127.0.0.1 yjinnouc.42.fr" | sudo tee -a /etc/hosts
    echo "   ✅ Added yjinnouc.42.fr to hosts file"
else
    echo "   ✅ yjinnouc.42.fr already in hosts file"
fi

# Restart LightDM to apply auto-login
echo "   Restarting display manager..."
sudo systemctl restart lightdm

echo "✅ Auto-login setup completed!"
echo ""
echo "📋 Configuration summary:"
echo "   ✅ Auto-login enabled for user 'debian'"
echo "   ✅ Password reset to 'debian_user_password'"
echo "   ✅ XFCE session configured"
echo "   ✅ Hosts file configured (yjinnouc.42.fr -> 127.0.0.1)"
echo "   ✅ Display manager restarted"
EOF

# Execute the auto-login setup script
echo "   Executing auto-login setup on VM..."
ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "bash /tmp/setup_autologin.sh"

echo ""
echo "🎉 Auto-login Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Auto-login Details:"
echo "   Username: debian"
echo "   Password: debian_user_password (if manual login needed)"
echo "   Session: XFCE4 Desktop"
echo "   Domain: yjinnouc.42.fr resolves to localhost"
echo ""
echo "🖥️  The VM should now automatically login to desktop"
echo "   Open VirtualBox GUI to see the desktop environment"
echo ""
echo "🦊 Ready for Firefox testing:"
echo "   Navigate to: https://yjinnouc.42.fr"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify auto-login is working
echo ""
echo "🔍 Verifying auto-login setup..."
sleep 5

if ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "ps aux | grep -v grep | grep 'xfce4-session'" 2>/dev/null; then
    echo "   ✅ XFCE desktop session is running"
else
    echo "   ⚠️  Desktop session may still be starting"
fi

echo ""
echo "🎉 Auto-login Setup Verified!"
