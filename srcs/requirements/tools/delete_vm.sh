#!/bin/bash

set -e

# Delete VM if it exists
echo "Checking for existing VM..."
if vboxmanage list vms | grep -q "Ubuntu-Inception"; then
		echo "VM 'Ubuntu-Inception' exists. Removing it..."
		vboxmanage unregistervm "Ubuntu-Inception" --delete
else
		echo "VM 'Ubuntu-Inception' does not exist. Nothing to remove."
fi

# Delete data directory if it exists
GOINFRE_DIR="/goinfre/yjinnouc"
VM_DIR="$GOINFRE_DIR/VMs/Ubuntu-Inception"
if [ -d "$VM_DIR" ]; then
		echo "Removing VM directory: $VM_DIR"
		rm -rf "$VM_DIR"
else
		echo "VM directory '$VM_DIR' does not exist. Nothing to remove."
fi
