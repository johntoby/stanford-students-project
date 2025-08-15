#!/bin/bash

# GitHub Actions Self-Hosted Runner Setup Script for AWS EC2
# Run this script on your EC2 instance to set up the GitHub Actions runner

set -e

echo "🚀 Setting up GitHub Actions Self-Hosted Runner on AWS EC2"
echo "=========================================================="

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y curl wget git build-essential

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    rm get-docker.sh
else
    echo "✅ Docker already installed"
fi

# Install Go
if ! command -v go &> /dev/null; then
    echo "🔨 Installing Go 1.21..."
    wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    source ~/.bashrc
    rm go1.21.0.linux-amd64.tar.gz
else
    echo "✅ Go already installed"
fi

# Create actions-runner directory
echo "📁 Setting up GitHub Actions runner directory..."
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download GitHub Actions runner
echo "⬇️  Downloading GitHub Actions runner..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep 'tag_name' | cut -d'"' -f4 | sed 's/v//')
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Extract runner
echo "📦 Extracting runner..."
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo ""
echo "✅ Setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Go to your GitHub repository settings"
echo "2. Navigate to Actions > Runners"
echo "3. Click 'New self-hosted runner'"
echo "4. Copy the configuration command and run it in ~/actions-runner/"
echo "5. Example:"
echo "   ./config.sh --url https://github.com/YOUR_USERNAME/stanford-students-project --token YOUR_TOKEN"
echo "6. Start the runner:"
echo "   ./run.sh"
echo ""
echo "🔗 For service setup (optional):"
echo "   sudo ./svc.sh install"
echo "   sudo ./svc.sh start"