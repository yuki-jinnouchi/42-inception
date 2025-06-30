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
    "cd /home/debian && git clone git@vogsphere-v2.42tokyo.jp:vogsphere/intra-uuid-66687ad6-3e3b-46c8-9b41-794152c14da2-6646051-yjinnouc inception"

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
echo "   sh $PROJECT_DIR/srcs/requirements/tools/vm_ssh.sh"
echo "   cd $PROJECT_DIR"
echo "   make up    # Start all services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
