#!/bin/bash

echo "🚀 Deploying Stanford Students API to Kubernetes..."

# Build Docker image
echo "📦 Building Docker image..."
docker build -t stanford-students-api:latest .

# Setup Vault and External Secrets first
echo "🔐 Setting up Vault and External Secrets..."
./k8s/setup-vault.sh

# Deploy Database
echo "🗄️ Deploying Database..."
kubectl apply -f k8s/database.yml

echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n student-api

# Deploy Application
echo "🚀 Deploying Application..."
kubectl apply -f k8s/application.yml

echo "⏳ Waiting for API to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/stanford-api -n student-api

echo "✅ Deployment complete!"
echo ""
echo "📊 Checking status..."
kubectl get pods -n vault-system
kubectl get pods -n external-secrets-system
kubectl get pods -n student-api
echo ""
echo "🔗 Access the application:"
echo "   Port Forward: kubectl port-forward service/stanford-api-service 8080:8080 -n student-api"
echo "   Then access: http://localhost:8080"