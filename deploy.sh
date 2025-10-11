#!/bin/bash

set -e  # Exit on any error

echo "🚀 Deploying Stanford Students API to Kubernetes..."

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

# Create namespaces if they don't exist
echo "📁 Creating namespaces..."
kubectl create namespace vault-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace external-secrets-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace student-api --dry-run=client -o yaml | kubectl apply -f -

# Build Docker image
echo "📦 Building Docker image..."
docker build -t johntoby/stanford-students-api:latest .

# Push Docker image to registry
echo "📤 Pushing Docker image to registry..."
docker push johntoby/stanford-students-api:latest

# Make setup-vault.sh executable and run it
echo "🔐 Setting up Vault and External Secrets..."
chmod +x k8s/setup-vault.sh
./k8s/setup-vault.sh

# Deploy Database first
echo "🗄️ Deploying Database..."
kubectl apply -f k8s/database.yml

echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n student-api

# Wait for database pod to be ready
echo "⏳ Waiting for PostgreSQL pod to be ready..."
kubectl wait --for=condition=ready --timeout=300s pod -l app=postgres -n student-api

# Deploy Application
echo "🚀 Deploying Application..."
kubectl apply -f k8s/application.yml

echo "⏳ Waiting for API to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/stanford-api -n student-api

# Wait for application pod to be ready
echo "⏳ Waiting for API pod to be ready..."
kubectl wait --for=condition=ready --timeout=300s pod -l app=stanford-api -n student-api

echo "✅ Deployment complete!"
echo ""
echo "📊 Checking status..."
echo "Vault System:"
kubectl get pods -n vault-system
echo ""
echo "External Secrets System:"
kubectl get pods -n external-secrets-system
echo ""
echo "Student API:"
kubectl get pods -n student-api
echo ""
echo "Services:"
kubectl get services -n student-api
echo ""
echo "🔗 Access the application:"
echo "   Port Forward: kubectl port-forward service/stanford-api-service 8080:8080 -n student-api"
echo "   Then access: http://localhost:8080"
echo ""
echo "💡 Useful commands:"
echo "   Check logs: kubectl logs -f deployment/stanford-api -n student-api"
echo "   Check database: kubectl logs -f deployment/postgres -n student-api"