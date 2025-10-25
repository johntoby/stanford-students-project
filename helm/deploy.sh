#!/bin/bash

set -e

echo "🚀 Starting Stanford Students API Helm deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="student-api"
RELEASE_NAME="stanford-students-stack"
CHART_PATH="./stanford-students-stack"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if Kubernetes cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_status "Adding required Helm repositories..."

# Add Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo add hashicorp https://helm.releases.hashicorp.com 2>/dev/null || true
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true

print_status "Updating Helm repositories..."
helm repo update

print_status "Updating chart dependencies..."
cd "$CHART_PATH"
helm dependency update
cd ..

print_status "Cleaning up any existing External Secrets CRDs..."
kubectl delete crd --ignore-not-found=true \
    acraccesstokens.generators.external-secrets.io \
    clustersecretstores.external-secrets.io \
    secretstores.external-secrets.io \
    externalsecrets.external-secrets.io \
    clusterpushsecrets.external-secrets.io \
    pushsecrets.external-secrets.io

print_status "Installing External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
    --namespace external-secrets-system \
    --create-namespace \
    --wait

print_status "Installing Vault..."
helm upgrade --install vault hashicorp/vault \
    --namespace vault-system \
    --create-namespace \
    --set "server.dev.enabled=true" \
    --set "server.dev.devRootToken=root" \
    --set "injector.enabled=false" \
    --wait

print_status "Creating namespace if it doesn't exist..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

print_status "Installing/Upgrading the Stanford Students Stack..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --wait \
    --timeout=10m \
    --create-namespace

print_success "Helm deployment completed!"

print_status "Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault-system --timeout=300s

# Setup Vault secrets
VAULT_POD=$(kubectl get pods -n vault-system -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')

print_status "Configuring Vault secrets..."
kubectl exec -n vault-system "$VAULT_POD" -- vault auth -method=token token=root
kubectl exec -n vault-system "$VAULT_POD" -- vault kv put secret/database username=postgres password=postgres

print_success "Vault secrets configured!"

print_status "Waiting for External Secrets Operator..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=external-secrets -n external-secrets-system --timeout=300s

print_status "Waiting for secrets to be created..."
kubectl wait --for=condition=Ready externalsecret postgres-credentials -n "$NAMESPACE" --timeout=300s
kubectl wait --for=condition=Ready externalsecret app-credentials -n "$NAMESPACE" --timeout=300s

print_status "Waiting for all application pods to be ready..."
kubectl wait --for=condition=ready pod --all -n "$NAMESPACE" --timeout=300s

print_status "Deployment Status:"
echo "===================="
kubectl get pods -n "$NAMESPACE"
echo ""
kubectl get svc -n "$NAMESPACE"
echo ""

print_success "🎉 Stanford Students API is now deployed!"
print_status "Access the application:"
echo "  - Frontend: kubectl port-forward -n $NAMESPACE svc/stanford-api-service 8080:8080"
echo "  - Then visit: http://localhost:8080"
echo ""
print_status "To check logs:"
echo "  kubectl logs -n $NAMESPACE -l app=stanford-api -f"
echo ""
print_status "To uninstall:"
echo "  ./cleanup.sh"