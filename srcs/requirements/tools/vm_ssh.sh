#!/bin/bash

# SSH connection script with Agent Forwarding for Git access
echo "🔗 Connecting to VM with SSH Agent Forwarding..."

### Configuration
SSH_PORT="2222"
SSH_USER="debian"
SSH_HOST="localhost"
VM_KEY_PRIVATE="$HOME/.ssh/id_rsa_42"

ssh -A -i "$VM_KEY_PRIVATE" -p $SSH_PORT $SSH_USER@$SSH_HOST
