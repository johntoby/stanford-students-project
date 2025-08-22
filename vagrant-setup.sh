#!/bin/bash

# Stanford Students API - Vagrant Setup Script
# Automatically installs all required tools and starts the application

set -e

echo "🚀 Stanford Students API - Vagrant Setup"
echo "========================================"

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install basic tools
echo "🔧 Installing basic tools..."
sudo apt install -y curl wget git build-essential apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker vagrant
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose (standalone)
echo "🐙 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
else
    echo "✅ Docker Compose already installed"
fi

# Install Make
echo "🔨 Installing Make..."
if ! command -v make &> /dev/null; then
    sudo apt install -y make
else
    echo "✅ Make already installed"
fi

# Install Go (for local development)
echo "🔨 Installing Go..."
if ! command -v go &> /dev/null; then
    GO_VERSION="1.21.0"
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    rm go${GO_VERSION}.linux-amd64.tar.gz
else
    echo "✅ Go already installed"
fi

# Verify installations
echo ""
echo "🔍 Verifying installations..."
echo "=============================="

docker --version
docker-compose --version
make --version

# Navigate to project directory
cd /home/vagrant/stanford-students-project

# Set proper permissions
sudo chown -R vagrant:vagrant /home/vagrant/stanford-students-project

# Build and start the application
echo ""
echo "🚀 Building and starting Stanford Students API..."
echo "================================================="

# Start the load-balanced application
make run-api

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 20

# Check service status
echo ""
echo "📊 Service Status:"
make status

echo ""
echo "🎉 Setup completed successfully!"
echo "================================"
echo ""
echo "📱 Access the application:"
echo "  Frontend (Load Balanced): http://localhost:8080"
echo "  API (Load Balanced): http://localhost:8080/api/v1"
echo "  Health Check: http://localhost:8080/healthcheck"
echo "  Nginx Health: http://localhost:8080/nginx-health"
echo ""
echo "🔗 Direct API Access:"
echo "  API Instance 1: http://localhost:8081"
echo "  API Instance 2: http://localhost:8082"
echo ""
echo "🛠️  Useful commands:"
echo "  vagrant ssh                    # SSH into the VM"
echo "  make status                    # Check container status"
echo "  make logs                      # View API logs"
echo "  make logs-nginx                # View nginx logs"
echo "  make stop-all                  # Stop all services"
echo ""
echo "📁 Project directory: /home/vagrant/stanford-students-project"