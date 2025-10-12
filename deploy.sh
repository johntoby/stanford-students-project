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

# Wait for External Secret to sync
echo "⏳ Waiting for database credentials to sync from Vault..."
for i in {1..30}; do
    if kubectl get secret postgres-secret -n student-api &>/dev/null; then
        echo "✅ Database credentials synced successfully"
        break
    fi
    echo "Waiting for External Secret to sync... ($i/30)"
    sleep 5
done

if ! kubectl get secret postgres-secret -n student-api &>/dev/null; then
    echo "❌ External Secret failed to sync. Checking External Secrets controller..."
    echo "External Secrets Controller status:"
    kubectl get pods -n external-secrets-system
    echo ""
    echo "External Secrets Controller logs:"
    kubectl logs -n external-secrets-system -l app=external-secrets-controller --tail=20
    echo ""
    echo "⚠️ Creating database secret manually as fallback..."
    kubectl create secret generic postgres-secret -n student-api \
        --from-literal=POSTGRES_USER=postgres \
        --from-literal=POSTGRES_PASSWORD=postgres \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ Manual secret created successfully"
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

# Wait for app credentials to sync
echo "⏳ Waiting for app credentials to sync from Vault..."
for i in {1..20}; do
    if kubectl get secret app-secret -n student-api &>/dev/null; then
        echo "✅ App credentials synced successfully"
        break
    fi
    echo "Waiting for app External Secret to sync... ($i/20)"
    sleep 3
done

if ! kubectl get secret app-secret -n student-api &>/dev/null; then
    echo "⚠️ Creating app secret manually as fallback..."
    kubectl create secret generic app-secret -n student-api \
        --from-literal=DB_USER=postgres \
        --from-literal=DB_PASSWORD=postgres \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ Manual app secret created successfully"
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