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

# Fix Vault secrets integration
echo "🔧 Fixing Vault Secret Issues..."
VAULT_POD=$(kubectl get pods -l app=vault -n vault-system -o jsonpath='{.items[0].metadata.name}')
echo "Vault pod: $VAULT_POD"

# Ensure Vault has proper secrets
kubectl exec -n vault-system $VAULT_POD -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    export VAULT_TOKEN=root && 
    
    # Enable KV engine (ignore if already enabled)
    vault secrets enable -path=secret kv-v2 2>/dev/null || echo 'KV engine already enabled' &&
    
    # Create database secrets
    vault kv put secret/database username=postgres password=postgres &&
    
    # Verify secrets were created
    echo 'Verifying secrets:' &&
    vault kv get secret/database
"

# Fix vault token secret
kubectl delete secret vault-token -n student-api --ignore-not-found
kubectl create secret generic vault-token -n student-api --from-literal=token=root

# Deploy Database first
echo "🗄️ Deploying Database..."
kubectl apply -f k8s/database.yml

# Force refresh ExternalSecrets
echo "🔄 Force refreshing ExternalSecrets..."
kubectl annotate externalsecret postgres-credentials -n student-api force-sync=$(date +%s) --overwrite || echo "postgres-credentials not found"

# Wait for ExternalSecrets to create secrets
echo "⏳ Waiting for ExternalSecrets to create database secrets..."
for i in {1..30}; do
    if kubectl get secret postgres-secret -n student-api &>/dev/null; then
        echo "✅ Database credentials created by ExternalSecrets"
        break
    fi
    echo "Waiting for ExternalSecrets to sync... ($i/30)"
    sleep 5
done

if ! kubectl get secret postgres-secret -n student-api &>/dev/null; then
    echo "❌ ExternalSecrets failed to create database secrets. Checking status..."
    echo "ExternalSecret postgres-credentials status:"
    kubectl describe externalsecret postgres-credentials -n student-api 2>/dev/null || echo "Not found"
    echo ""
    echo "External Secrets Controller logs:"
    kubectl logs -l app=external-secrets-controller -n external-secrets-system --tail=10
    echo ""
    echo "❌ Database secrets not created automatically. Please check ExternalSecrets configuration."
    exit 1
fi

echo "⏳ Waiting for PostgreSQL to be ready..."
if ! kubectl wait --for=condition=available --timeout=120s deployment/postgres -n student-api; then
    echo "❌ PostgreSQL deployment failed. Checking status..."
    echo "Deployment status:"
    kubectl describe deployment postgres -n student-api
    echo ""
    echo "Pod status:"
    kubectl get pods -l app=postgres -n student-api
    echo ""
    echo "Pod logs:"
    kubectl logs -l app=postgres -n student-api --tail=50
    echo ""
    echo "External Secret status:"
    kubectl describe externalsecret postgres-credentials -n student-api
    exit 1
fi

# Wait for database pod to be ready
echo "⏳ Waiting for PostgreSQL pod to be ready..."
kubectl wait --for=condition=ready --timeout=120s pod -l app=postgres -n student-api

# Deploy Application
echo "🚀 Deploying Application..."
kubectl apply -f k8s/application.yml

# Force refresh app ExternalSecrets
kubectl annotate externalsecret app-credentials -n student-api force-sync=$(date +%s) --overwrite || echo "app-credentials not found"

# Wait for ExternalSecrets to create app secrets
echo "⏳ Waiting for ExternalSecrets to create app secrets..."
for i in {1..30}; do
    if kubectl get secret app-secret -n student-api &>/dev/null; then
        echo "✅ App credentials created by ExternalSecrets"
        break
    fi
    echo "Waiting for ExternalSecrets to sync... ($i/30)"
    sleep 5
done

if ! kubectl get secret app-secret -n student-api &>/dev/null; then
    echo "❌ ExternalSecrets failed to create app secrets. Checking status..."
    echo "ExternalSecret app-credentials status:"
    kubectl describe externalsecret app-credentials -n student-api 2>/dev/null || echo "Not found"
    echo ""
    echo "External Secrets Controller logs:"
    kubectl logs -l app=external-secrets-controller -n external-secrets-system --tail=10
    echo ""
    echo "❌ App secrets not created automatically. Please check ExternalSecrets configuration."
    exit 1
fi

echo "⏳ Waiting for API to be ready..."
if ! kubectl wait --for=condition=available --timeout=300s deployment/stanford-api -n student-api; then
    echo "❌ API deployment failed. Checking status..."
    echo "Deployment status:"
    kubectl describe deployment stanford-api -n student-api
    echo ""
    echo "Pod status:"
    kubectl get pods -l app=stanford-api -n student-api
    echo ""
    echo "Pod logs:"
    kubectl logs -l app=stanford-api -n student-api --tail=50
    exit 1
fi

# Wait for application pod to be ready
echo "⏳ Waiting for API pod to be ready..."
kubectl wait --for=condition=ready --timeout=300s pod -l app=stanford-api -n student-api

echo "✅ Deployment complete!"
echo ""
echo "📊 Checking status..."
echo "Student API Pods:"
kubectl get pods -l app=stanford-api -n student-api
echo ""
echo "Services:"
kubectl get services -n student-api
echo ""
echo "🔍 Testing application health..."
echo "API logs (last 10 lines):"
kubectl logs -l app=stanford-api -n student-api --tail=10
echo ""
echo "Testing health endpoint:"
kubectl exec -n student-api deployment/stanford-api -- curl -f http://localhost:8080/healthcheck || echo "Health check failed"
echo ""
echo "🔗 Access the application on AWS EC2:"
echo "   Option 1 - Port Forward (from your local machine):"
echo "     ssh -L 8080:localhost:8080 ec2-user@YOUR_EC2_IP"
echo "     Then on EC2: kubectl port-forward service/stanford-api-service 8080:8080 -n student-api"
echo "     Open: http://localhost:8080"
echo ""
echo "   Option 2 - Direct EC2 access:"
echo "     On EC2: kubectl port-forward --address 0.0.0.0 service/stanford-api-service 8080:8080 -n student-api"
echo "     Open: http://YOUR_EC2_PUBLIC_IP:8080"
echo "     (Make sure port 8080 is open in EC2 security group)"
echo ""
echo "   Option 3 - LoadBalancer (recommended):"
echo "     kubectl patch service stanford-api-service -n student-api -p '{\"spec\":{\"type\":\"LoadBalancer\"}}'"
echo "     kubectl get service stanford-api-service -n student-api (wait for EXTERNAL-IP)"
echo ""
echo "💡 Troubleshooting commands:"
echo "   Check API logs: kubectl logs -f deployment/stanford-api -n student-api"
echo "   Check DB logs: kubectl logs -f deployment/postgres -n student-api"
echo "   Test connectivity: kubectl exec -n student-api deployment/stanford-api -- curl http://localhost:8080/healthcheck"
echo "   Get LoadBalancer IP: kubectl get service stanford-api-service -n student-api"
echo ""
echo "⚠️  AWS EC2 Notes:"
echo "   - Ensure EC2 security group allows inbound traffic on port 8080"
echo "   - For LoadBalancer, you need AWS Load Balancer Controller installed"
echo "   - Replace YOUR_EC2_IP with your actual EC2 public IP address"