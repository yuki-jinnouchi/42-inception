#!/bin/bash

set -e

# Git Project Setup Script for VM
echo "📋 Setting up Git project on VM..."

### Configuration
SSH_PORT="2222"
SSH_USER="debian"
SSH_HOST="localhost"
VM_KEY_PRIVATE="$HOME/.ssh/id_rsa_42"
PROJECT_DIR="/home/debian/inception"

# Check if SSH key exists
if [ ! -f "$VM_KEY_PRIVATE" ]; then
    echo "❌ Error: SSH key not found at $VM_KEY_PRIVATE"
    echo "   Please run setup_ssh_keys.sh first"
    exit 1
fi

echo "   Testing SSH connection..."
if ! ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'SSH connection successful'" >/dev/null 2>&1; then
    echo "❌ Error: SSH connection failed"
    echo "   Please ensure VM is running and SSH keys are configured"
    exit 1
fi

### Install Git on VM
echo "   Installing Git..."
ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "sudo apt-get update -qq && sudo apt-get install -y git"

### Clone project with Agent Forwarding
echo "   Cloning Inception project..."
ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "cd /home/debian && git clone git@vogsphere-v2.42tokyo.jp:vogsphere/intra-uuid-9e0b1fb3-9813-4502-a4e2-e1ef57a9af3f-6625474-yjinnouc inception"

### Transfer secrets (not in git)
echo "   Transferring secrets..."
ROOT_DIR="$(pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"

if [ -d "$SECRETS_DIR" ]; then
    scp -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -P $SSH_PORT -r "$SECRETS_DIR" $SSH_USER@$SSH_HOST:$PROJECT_DIR/
    echo "   ✅ Secrets transferred"
else
    echo "   ⚠️  Secrets directory not found: $SECRETS_DIR"
fi

### Set up project permissions and environment
echo "   Setting up project environment..."
ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "cd $PROJECT_DIR && \
     find . -name '*.sh' -exec chmod +x {} \; && \
     sudo chown -R debian:debian $PROJECT_DIR"

### Verify setup
echo "   Verifying project setup..."
PROJECT_STATUS=$(ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "cd $PROJECT_DIR && \
     echo 'Project directory:' && pwd && \
     echo 'Git status:' && git status --porcelain | wc -l && \
     echo 'Docker compose file:' && ls -la srcs/docker-compose.yml 2>/dev/null || echo 'Not found' && \
     echo 'Secrets:' && ls -la secrets/ 2>/dev/null || echo 'Not found' && \
     echo 'Makefile:' && ls -la Makefile 2>/dev/null || echo 'Not found'")

echo "   📋 Project Status:"
echo "$PROJECT_STATUS" | sed 's/^/     /'

echo ""
echo "🎉 Git Project Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Project Information:"
echo "   Location: $PROJECT_DIR"
echo "   Repository: VogSphere (42Tokyo)"
echo "   Secrets: Transferred locally"
echo ""
echo "📝 Next steps:"
echo "   ssh -A -i $VM_KEY_PRIVATE -p $SSH_PORT $SSH_USER@$SSH_HOST"
echo "   cd $PROJECT_DIR"
echo "   make up    # Start all services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
