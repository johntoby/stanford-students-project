#!/bin/bash

set -e

echo "🚀 Deploying Stanford Students Stack with Helm..."

# Clean up existing CRDs if they exist
echo "🧹 Cleaning up existing CRDs..."
kubectl delete crd secretstores.external-secrets.io --ignore-not-found=true
kubectl delete crd externalsecrets.external-secrets.io --ignore-not-found=true

# Update dependencies
echo "📦 Updating Helm dependencies..."
cd stanford-students-stack
helm dependency update
cd ..

# Install CRDs first
echo "📋 Installing External Secrets CRDs..."
kubectl apply -f crds.yaml

# Wait for CRDs to be ready
echo "⏳ Waiting for CRDs to be ready..."
sleep 5

# Deploy the stack
echo "🔧 Installing/Upgrading Stanford Students Stack..."
helm upgrade --install stanford-students-stack ./stanford-students-stack \
  --namespace student-api \
  --create-namespace \
  --wait \
  --timeout 10m

echo "✅ Deployment completed successfully!"

# Show status
echo "📊 Checking deployment status..."
kubectl get pods -n student-api
kubectl get pods -n vault-system
kubectl get pods -n external-secrets-system

echo "🌐 Access the application at: http://localhost:8080"
echo "🔍 Health check: http://localhost:8080/healthcheck"