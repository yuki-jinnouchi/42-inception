#!/bin/bash

set -e

# =============================================================================
# VM Setup Script - Complete Inception Environment Setup
# =============================================================================

echo "🔧 Setting up Debian VM for Inception project..."
echo "   This script will configure SSH, Docker, and clone the project"

### Configuration
VM_NAME="Debian-Inception"
SSH_PORT="2222"
SSH_USER="debian"
SSH_HOST="localhost"
ROOT_DIR="$(pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"

### Wait for VM to be ready
echo "📋 Waiting for VM to be ready..."

# Check if VM is running
while ! VBoxManage list runningvms | grep -q "$VM_NAME"; do
    echo "   Waiting for VM '$VM_NAME' to start..."
    sleep 5
done

echo "   ✅ VM '$VM_NAME' is running"

# Wait for SSH to be available
echo "   Waiting for SSH service..."
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if nc -z localhost $SSH_PORT 2>/dev/null; then
        echo "   ✅ SSH port is accessible"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "   Waiting for SSH (attempt $((RETRY_COUNT))/$MAX_RETRIES)..."
    sleep 10
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "   ❌ SSH port not available after $MAX_RETRIES attempts"
    echo "   💡 VM might still be installing. Check VirtualBox GUI."
    exit 1
fi

# Clear old host keys for new VM
echo "   Clearing old host keys..."
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:$SSH_PORT" 2>/dev/null || true

echo "   ✅ VM is ready for setup"

### Step 1: Setup SSH Keys and Agent Forwarding
echo ""
echo "🔐 Step 1/3: Setting up SSH keys and Agent Forwarding..."
if [ -f "$ROOT_DIR/srcs/requirements/tools/setup_ssh_keys.sh" ]; then
    "$ROOT_DIR/srcs/requirements/tools/setup_ssh_keys.sh"
    if [ $? -eq 0 ]; then
        echo "   ✅ SSH keys configured successfully"
    else
        echo "   ❌ SSH key setup failed"
        exit 1
    fi
else
    echo "   ❌ setup_ssh_keys.sh not found"
    exit 1
fi

### Step 2: Install Docker and Docker Compose
echo ""
echo "🐋 Step 2/3: Installing Docker and Docker Compose..."
if [ -f "$ROOT_DIR/srcs/requirements/tools/install_docker.sh" ]; then
    # Transfer and execute Docker installation
    VM_KEY_PRIVATE="$HOME/.ssh/id_rsa_42"
    
    echo "   Transferring Docker installation script..."
    scp -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -P $SSH_PORT \
        "$ROOT_DIR/srcs/requirements/tools/install_docker.sh" $SSH_USER@$SSH_HOST:/tmp/
    
    echo "   Installing Docker on VM..."
    ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
        "bash /tmp/install_docker.sh"
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Docker installed successfully"
    else
        echo "   ❌ Docker installation failed"
        exit 1
    fi
else
    echo "   ❌ install_docker.sh not found"
    exit 1
fi

### Step 3: Setup Git Project
echo ""
echo "📁 Step 3/3: Setting up Git project..."
if [ -f "$ROOT_DIR/srcs/requirements/tools/setup_gitproject.sh" ]; then
    "$ROOT_DIR/srcs/requirements/tools/setup_gitproject.sh"
    if [ $? -eq 0 ]; then
        echo "   ✅ Git project setup successfully"
    else
        echo "   ❌ Git project setup failed"
        exit 1
    fi
else
    echo "   ❌ setup_gitproject.sh not found"
    exit 1
fi

### Final Verification
echo ""
echo "🔍 Final verification..."
VM_KEY_PRIVATE="$HOME/.ssh/id_rsa_42"
PROJECT_DIR="/home/debian/inception"

FINAL_STATUS=$(ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "cd $PROJECT_DIR && \
     echo 'Docker version:' && docker --version && \
     echo 'Docker Compose version:' && docker-compose --version && \
     echo 'Project files:' && ls -la && \
     echo 'Git status:' && git status --porcelain | wc -l && \
     echo 'Ready for make up!' ")

echo "   📋 System Status:"
echo "$FINAL_STATUS" | sed 's/^/     /'

echo ""
echo "🎉 VM Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Environment Ready:"
echo "   ✅ SSH Keys: Agent Forwarding enabled"
echo "   ✅ Docker: Latest version installed"
echo "   ✅ Project: Cloned from VogSphere"
echo "   ✅ Secrets: Transferred securely"
echo ""
echo "🔗 Access Information:"
echo "   SSH Access: ssh -A -i $VM_KEY_PRIVATE -p $SSH_PORT $SSH_USER@$SSH_HOST"
echo "   Or use: ./srcs/requirements/tools/vm_ssh.sh"
echo "   Project Directory: $PROJECT_DIR"
echo ""
echo "🚀 Quick Start:"
echo "   ./srcs/requirements/tools/vm_ssh.sh"
echo "   cd $PROJECT_DIR"
echo "   make up      # Start all services"
echo "   make ps      # Check service status"
echo "   make logs    # View service logs"
echo ""
echo "🌐 Service URLs (after 'make up'):"
echo "   WordPress: https://localhost:8443"
echo "   Adminer: http://localhost:8080"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
