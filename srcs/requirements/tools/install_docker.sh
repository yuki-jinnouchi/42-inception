#!/bin/bash

set -e

# Docker Installation Script for Debian VM
echo "🐋 Installing Docker and Docker Compose..."

### Update package manager
echo "   Updating package manager..."
# Remove CD-ROM repository if it exists to avoid installation errors
sudo sed -i '/cdrom/d' /etc/apt/sources.list 2>/dev/null || true
sudo apt-get update -qq

### Install dependencies
echo "   Installing dependencies..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    make

### Add Docker's official GPG key
echo "   Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

### Add Docker repository
echo "   Adding Docker repository..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### Install Docker
echo "   Installing Docker..."
sudo apt-get update -qq
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

### Add user to docker group
echo "   Adding user to docker group..."
sudo usermod -aG docker debian

### Install Docker Compose
echo "   Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.24.0"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink for compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

### Start and enable Docker
echo "   Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

echo "   ✅ Docker installation complete"
docker --version
docker-compose --version
