#!/bin/bash

set -e

echo "🚀 Deploying Stanford Students Stack with Helm..."

# Update dependencies
echo "📦 Updating Helm dependencies..."
cd stanford-students-stack
helm dependency update
cd ..

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