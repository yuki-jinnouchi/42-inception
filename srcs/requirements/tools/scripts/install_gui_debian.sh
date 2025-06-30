#!/bin/bash

set -e

# Install GUI Environment on Debian VM
echo "🖥️  Installing GUI environment on Debian VM..."

### Configuration
VM_NAME="Debian-Inception"
SSH_PORT="2222"
SSH_USER="debian"
SSH_HOST="localhost"
VM_KEY_PRIVATE="$HOME/.ssh/id_rsa_42"

### Check SSH connection
echo "📋 Checking SSH connection..."
if ! ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'SSH OK'" 2>/dev/null; then
    echo "❌ SSH connection failed. Please run setup_vm_debian.sh first."
    exit 1
fi

echo "   ✅ SSH connection OK"

### Install GUI Environment
echo ""
echo "🖥️  Installing lightweight desktop environment..."

# Transfer and execute GUI installation script
cat << 'EOF' | ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "cat > /tmp/install_gui.sh"
#!/bin/bash

echo "🖥️  Installing GUI components..."

# Update package list
echo "   Updating package list..."
sudo apt-get update -qq

# Install X11 and lightweight desktop environment
echo "   Installing X11 and XFCE desktop..."
sudo apt-get install -y \
    xorg \
    xfce4 \
    xfce4-goodies \
    lightdm \
    firefox-esr \
    dbus-x11 \
    pulseaudio \
    pavucontrol

# Configure LightDM for auto-login (optional)
echo "   Configuring display manager..."
sudo systemctl enable lightdm

# Install additional useful GUI packages
echo "   Installing additional GUI tools..."
sudo apt-get install -y \
    mousepad \
    ristretto \
    thunar-archive-plugin \
    xfce4-terminal \
    task-xfce-desktop

# Try to install optional packages (don't fail if not available)
echo "   Installing optional GUI packages..."
for package in file-manager-actions; do
    if sudo apt-get install -y "$package" 2>/dev/null; then
        echo "     ✅ Installed $package"
    else
        echo "     ⚠️  Skipped $package (not available)"
    fi
done

# Configure VirtualBox guest additions if available
if lspci | grep -i virtualbox > /dev/null; then
    echo "   Installing VirtualBox Guest Additions..."
    sudo apt-get install -y virtualbox-guest-utils virtualbox-guest-x11
fi

# Enable GUI services
echo "   Enabling GUI services..."
sudo systemctl set-default graphical.target
sudo systemctl enable lightdm

# Create Firefox desktop shortcut
echo "   Creating Firefox desktop shortcut..."
mkdir -p /home/debian/Desktop
cat > /home/debian/Desktop/firefox.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Comment=Web Browser
Exec=firefox-esr %u
Icon=firefox-esr
Terminal=false
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
Categories=Network;WebBrowser;
Keywords=Internet;WWW;Browser;Web;Explorer
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=Open a New Window
Exec=firefox-esr -new-window

[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=firefox-esr -private-window
DESKTOP_EOF

chmod +x /home/debian/Desktop/firefox.desktop

echo "✅ GUI installation completed!"
echo ""
echo "📋 Installed components:"
echo "   ✅ X11 (X Window System)"
echo "   ✅ XFCE4 (Lightweight desktop environment)"
echo "   ✅ LightDM (Display manager)"
echo "   ✅ Firefox ESR (Web browser)"
echo "   ✅ VirtualBox Guest Additions"
echo ""
echo "🔄 Rebooting system to start GUI..."
sudo reboot
EOF

# Execute the installation script
echo "   Executing GUI installation on VM..."
ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "bash /tmp/install_gui.sh"

echo ""
echo "🎉 GUI Installation Started!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 GUI Environment Details:"
echo "   Desktop: XFCE4 (Lightweight and fast)"
echo "   Display Manager: LightDM"
echo "   Browser: Firefox ESR"
echo "   Terminal: XFCE4 Terminal"
echo ""
echo "🔄 VM is rebooting to start GUI mode..."
echo "   Wait 30-60 seconds for reboot to complete"
echo ""
echo "🖥️  VirtualBox GUI Access:"
echo "   1. Open VirtualBox Manager"
echo "   2. Select '$VM_NAME' VM"
echo "   3. Click 'Show' to open VM window"
echo "   4. GUI desktop should appear automatically"
echo ""
echo "🦊 Firefox Testing:"
echo "   1. Open Firefox from desktop or applications menu"
echo "   2. Navigate to: https://yjinnouc.42.fr"
echo "   3. Test WordPress installation"
echo ""
echo "💡 Alternative CLI access:"
echo "   SSH: ssh -A -i $VM_KEY_PRIVATE -p $SSH_PORT $SSH_USER@$SSH_HOST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Wait for reboot and check GUI availability
echo ""
echo "⏳ Waiting for VM to reboot..."
sleep 30

echo "🔍 Checking VM status after reboot..."
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ssh -A -i "$VM_KEY_PRIVATE" -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'VM ready'" 2>/dev/null; then
        echo "   ✅ VM is back online"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "   Waiting for VM (attempt $((RETRY_COUNT))/$MAX_RETRIES)..."
    sleep 10
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "   ⚠️  VM taking longer than expected to reboot"
    echo "   Check VirtualBox GUI for current status"
else
    # Check if GUI is running
    if ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "ps aux | grep -v grep | grep -q lightdm" 2>/dev/null; then
        echo "   ✅ GUI environment is running"
    else
        echo "   ⚠️  GUI environment may still be starting"
    fi
fi

echo ""
echo "🎉 GUI Installation Complete!"
echo "Open VirtualBox GUI to access the desktop environment."
