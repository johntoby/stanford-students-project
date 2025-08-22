# Vagrant Deployment Guide

## Prerequisites
- **VirtualBox** (6.1 or higher)
- **Vagrant** (2.3 or higher)

## Quick Start

### 1. Start the VM and Deploy
```bash
# Navigate to project directory
cd stanford-students-project

# Start VM and auto-deploy application
vagrant up
```

### 2. Access the Application
- **Frontend**: http://localhost:8080
- **API**: http://localhost:8080/api/v1
- **Health Check**: http://localhost:8080/healthcheck
- **Direct API 1**: http://localhost:8081
- **Direct API 2**: http://localhost:8082

## Vagrant Commands

### VM Management
```bash
vagrant up          # Start and provision VM
vagrant halt        # Stop VM
vagrant reload       # Restart VM
vagrant destroy      # Delete VM
vagrant status       # Show VM status
```

### SSH and Development
```bash
vagrant ssh          # SSH into VM
vagrant ssh -c "make status"  # Run command in VM
```

### Inside the VM
```bash
# Navigate to project
cd /home/vagrant/stanford-students-project

# Application management
make status          # Check container status
make logs           # View API logs
make logs-nginx     # View nginx logs
make stop-all       # Stop all services
make run-api        # Restart services
make clean          # Clean up containers

# Development
make build          # Build Go application
make test           # Run tests
make lint           # Run linting
```

## VM Configuration
- **OS**: Ubuntu 24.04 LTS
- **Memory**: 2GB RAM
- **CPUs**: 2 cores
- **Hostname**: stanford-api-vm

## Port Forwarding
- `8080` → Load Balanced API (nginx)
- `8081` → API Instance 1
- `8082` → API Instance 2
- `5432` → PostgreSQL Database

## Troubleshooting

### If services don't start automatically:
```bash
vagrant ssh
cd /home/vagrant/stanford-students-project
make run-api
```

### If ports are already in use:
```bash
# Stop any local services using these ports
# Or modify Vagrantfile port mappings
```

### To rebuild everything:
```bash
vagrant ssh
cd /home/vagrant/stanford-students-project
make clean
make run-api
```

## What Gets Installed
- Docker & Docker Compose
- Make
- Go 1.21
- Git & build tools
- All project dependencies

## Architecture in VM
```
┌─────────────────────────────────────┐
│            Vagrant VM               │
│         (Ubuntu 24.04)              │
│                                     │
│  ┌─────────────────┐                │
│  │   nginx:80      │ ← Port 8080    │
│  │  Load Balancer  │                │
│  └─────────────────┘                │
│           │                         │
│      ┌────┴────┐                    │
│      │         │                    │
│  ┌───▼───┐ ┌───▼───┐                │
│  │ app1  │ │ app2  │                │
│  │:8081  │ │:8082  │                │
│  └───────┘ └───────┘                │
│      │         │                    │
│      └────┬────┘                    │
│           │                         │
│     ┌─────▼─────┐                   │
│     │ postgres  │                   │
│     │   :5432   │                   │
│     └───────────┘                   │
└─────────────────────────────────────┘
```