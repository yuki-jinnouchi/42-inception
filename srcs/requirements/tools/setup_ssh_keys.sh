#!/bin/bash

set -e

# SSH Key Setup for VM Access with Agent Forwarding
echo "🔑 Setting up SSH key authentication for VM with Agent Forwarding..."

### Configuration
SSH_PORT="2222"
SSH_USER="debian"
SSH_HOST="localhost"
ROOT_DIR="$(pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"

# Use existing Git SSH key for VM access (no separate key needed)
VM_KEY_PRIVATE="$HOME/.ssh/id_rsa_42"
VM_KEY_PUBLIC="$HOME/.ssh/id_rsa_42.pub"

# Check if Git SSH key exists
if [ ! -f "$VM_KEY_PRIVATE" ] || [ ! -f "$VM_KEY_PUBLIC" ]; then
    echo "❌ Error: SSH key not found at $VM_KEY_PRIVATE"
    echo "   Please make sure your SSH key exists"
    exit 1
fi

# Get VM password for initial setup
if [ ! -f "$SECRETS_DIR/debian_password.txt" ]; then
    echo "❌ Error: Debian password file not found: $SECRETS_DIR/debian_password.txt"
    exit 1
fi
DEBIAN_PASSWORD=$(cat "$SECRETS_DIR/debian_password.txt")

### Setup SSH key authentication
echo "📋 Setting up key-based authentication using existing Git key..."

# Wait for VM to be ready
echo "   Waiting for VM SSH service..."
sleep 5

# Test if SSH is available
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if nc -z localhost $SSH_PORT 2>/dev/null; then
        echo "   ✅ SSH port is open"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "   Waiting for SSH (attempt $((RETRY_COUNT))/$MAX_RETRIES)..."
    sleep 5
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "   ❌ SSH port not available after $MAX_RETRIES attempts"
    exit 1
fi

# Copy public key to VM (this will require manual password entry once)
echo "   Setting up authorized_keys..."
echo "   Password: $DEBIAN_PASSWORD"

# First, test if SSH key authentication already works
if ssh -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -o PasswordAuthentication=no -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'SSH key already configured'" 2>/dev/null; then
    echo "   ✅ SSH key authentication already working"
else
    echo "   Setting up SSH key authentication..."
    echo "   💡 You will be prompted for the VM password ONCE: $DEBIAN_PASSWORD"

    # Try ssh-copy-id with force option first
    if ssh-copy-id -f -i "$VM_KEY_PUBLIC" -p $SSH_PORT $SSH_USER@$SSH_HOST 2>/dev/null; then
        echo "   ✅ SSH key copied with ssh-copy-id"
    else
        echo "   ⚠️  ssh-copy-id failed, trying manual method..."

        # Manual method as fallback
        echo "   Please enter VM password when prompted: $DEBIAN_PASSWORD"
        ssh -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
            "mkdir -p ~/.ssh && chmod 700 ~/.ssh" && \
        cat "$VM_KEY_PUBLIC" | ssh -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
            "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys"

        echo "   ✅ SSH key copied manually"
    fi
fi

echo "   ✅ SSH key authentication configured"

### Setup SSH Agent Forwarding for Git access
echo "📋 Setting up SSH Agent Forwarding for Git access..."

# Ensure SSH agent is running and key is loaded
if ! ssh-add -l | grep -q "id_rsa_42"; then
    echo "   Adding SSH key to agent..."
    ssh-add "$VM_KEY_PRIVATE" 2>/dev/null || echo "   ⚠️  Key may already be loaded"
fi

# Create minimal SSH config on VM for Git (no private key needed)
ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "cat > ~/.ssh/config << 'EOF'
Host vogsphere-v2.42tokyo.jp
    HostName vogsphere-v2.42tokyo.jp
    User git
    StrictHostKeyChecking no
    ForwardAgent yes
Host *
    ForwardAgent yes
EOF
chmod 600 ~/.ssh/config"

echo "   ✅ SSH Agent Forwarding configured on VM"

# Test Git access with Agent Forwarding
echo "   Testing VogSphere SSH access with Agent Forwarding..."
if ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST \
    "ssh -T git@vogsphere-v2.42tokyo.jp 2>&1 | grep -q 'successfully authenticated'" 2>/dev/null; then
    echo "   ✅ VogSphere SSH authentication working via Agent Forwarding"
else
    echo "   ⚠️  VogSphere SSH test failed (may need host key acceptance)"
fi

### Test key-based authentication
echo "📋 Testing key-based authentication..."

if ssh -A -i "$VM_KEY_PRIVATE" -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_HOST "echo 'Key authentication successful'" 2>/dev/null; then
    echo "   ✅ Key-based authentication working"
    echo ""
    echo "🎉 SSH Agent Forwarding Setup Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 SSH Access with Agent Forwarding:"
    echo "   ssh -A -i $VM_KEY_PRIVATE -p $SSH_PORT $SSH_USER@$SSH_HOST"
    echo ""
    echo "📋 SCP Access:"
    echo "   scp -i $VM_KEY_PRIVATE -P $SSH_PORT file $SSH_USER@$SSH_HOST:/path/"
    echo ""
    echo "📋 Git SSH configured via Agent Forwarding:"
    echo "   ✅ No private keys stored on VM (secure)"
    echo "   ✅ Git operations use forwarded local key"
    echo "   Ready for VogSphere Git clone via SSH"
    echo "   Repository: git@vogsphere-v2.42tokyo.jp:vogsphere/intra-uuid-9e0b1fb3-9813-4502-a4e2-e1ef57a9af3f-6625474-yjinnouc"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "   ❌ Key-based authentication failed"
    exit 1
fi
