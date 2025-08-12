#!/bin/bash

# Stanford Students API - Prerequisites Installation Script
# This script installs Docker, Docker Compose, Make, and Git

set -e  # Exit on any error

echo "🚀 Stanford Students API - Prerequisites Installation"
echo "===================================================="

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "ubuntu"
        elif [ -f /etc/redhat-release ]; then
            echo "centos"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install on Ubuntu/Debian
install_ubuntu() {
    echo "📦 Installing prerequisites for Ubuntu/Debian..."
    
    # Update package list
    sudo apt update
    
    # Install basic tools
    sudo apt install -y curl wget gnupg lsb-release
    
    # Install Git
    if ! command_exists git; then
        echo "📥 Installing Git..."
        sudo apt install -y git
    else
        echo "✅ Git already installed"
    fi
    
    # Install Make
    if ! command_exists make; then
        echo "🔨 Installing Make..."
        sudo apt install -y make
    else
        echo "✅ Make already installed"
    fi
    
    # Install Docker
    if ! command_exists docker; then
        echo "🐳 Installing Docker..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        echo "✅ Docker already installed"
    fi
    
    # Install Docker Compose
    if ! command_exists docker-compose; then
        echo "🐙 Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "✅ Docker Compose already installed"
    fi
}

# Function to install on CentOS/RHEL
install_centos() {
    echo "📦 Installing prerequisites for CentOS/RHEL..."
    
    # Install basic tools
    sudo yum install -y curl wget
    
    # Install Git
    if ! command_exists git; then
        echo "📥 Installing Git..."
        sudo yum install -y git
    else
        echo "✅ Git already installed"
    fi
    
    # Install Make
    if ! command_exists make; then
        echo "🔨 Installing Make..."
        sudo yum install -y make
    else
        echo "✅ Make already installed"
    fi
    
    # Install Docker
    if ! command_exists docker; then
        echo "🐳 Installing Docker..."
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        echo "✅ Docker already installed"
    fi
    
    # Install Docker Compose
    if ! command_exists docker-compose; then
        echo "🐙 Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "✅ Docker Compose already installed"
    fi
}

# Function to install on macOS
install_macos() {
    echo "📦 Installing prerequisites for macOS..."
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "✅ Homebrew already installed"
    fi
    
    # Install tools via Homebrew
    echo "📥 Installing tools via Homebrew..."
    brew install git make docker docker-compose
    
    echo "⚠️  Note: You may need to start Docker Desktop manually"
}

# Function to verify installations
verify_installations() {
    echo ""
    echo "🔍 Verifying installations..."
    echo "=============================="
    
    if command_exists git; then
        echo "✅ Git: $(git --version)"
    else
        echo "❌ Git: Not found"
    fi
    
    if command_exists make; then
        echo "✅ Make: $(make --version | head -n1)"
    else
        echo "❌ Make: Not found"
    fi
    
    if command_exists docker; then
        echo "✅ Docker: $(docker --version)"
    else
        echo "❌ Docker: Not found"
    fi
    
    if command_exists docker-compose; then
        echo "✅ Docker Compose: $(docker-compose --version)"
    else
        echo "❌ Docker Compose: Not found"
    fi
}

# Main installation logic
main() {
    OS=$(detect_os)
    echo "🖥️  Detected OS: $OS"
    echo ""
    
    case $OS in
        "ubuntu")
            install_ubuntu
            ;;
        "centos")
            install_centos
            ;;
        "macos")
            install_macos
            ;;
        *)
            echo "❌ Unsupported operating system: $OS"
            echo "Please install the following manually:"
            echo "  - Git"
            echo "  - Make"
            echo "  - Docker (20.10+)"
            echo "  - Docker Compose (2.0+)"
            exit 1
            ;;
    esac
    
    verify_installations
    
    echo ""
    echo "🎉 Installation completed!"
    echo "========================="
    echo ""
    echo "📋 Next steps:"
    echo "1. Log out and log back in (or run: newgrp docker)"
    echo "2. Clone the repository: git clone <repository-url>"
    echo "3. Navigate to project: cd stanford-students-project"
    echo "4. Start the application: make run-api"
    echo ""
    echo "🔗 Access the application at: http://localhost:8080"
}

# Run main function
main "$@"