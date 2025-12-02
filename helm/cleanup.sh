#!/bin/bash

set -e

echo "🧹 Starting cleanup of Stanford Students API Helm deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="student-api"
#VAULT_NAMESPACE="vault-system"
#EXTERNAL_SECRETS_NAMESPACE="external-secrets-system"
RELEASE_NAME="stanford-students-stack"

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
    print_error "Helm is not installed."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed."
    exit 1
fi

print_status "Uninstalling Helm release..."
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" 2>/dev/null || print_warning "Release $RELEASE_NAME not found or already uninstalled"

print_status "Cleaning up namespaces..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
kubectl delete namespace "$VAULT_NAMESPACE" --ignore-not-found=true
kubectl delete namespace "$EXTERNAL_SECRETS_NAMESPACE" --ignore-not-found=true

print_status "Cleaning up CRDs..."
kubectl delete crd secretstores.external-secrets.io --ignore-not-found=true
kubectl delete crd externalsecrets.external-secrets.io --ignore-not-found=true

print_status "Cleaning up any remaining resources..."
kubectl delete clusterrole external-secrets-controller --ignore-not-found=true
kubectl delete clusterrolebinding external-secrets-controller --ignore-not-found=true

print_success "🎉 Cleanup completed!"
print_status "All Stanford Students API resources have been removed from the cluster."