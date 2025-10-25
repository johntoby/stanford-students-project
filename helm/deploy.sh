#!/bin/bash

set -e

echo "🚀 Starting Stanford Students API Helm deployment..."

# Configuration
NAMESPACE="student-api"
RELEASE_NAME="stanford-students-stack"
CHART_PATH="./stanford-students-stack"

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "📁 Creating namespaces..."
kubectl create namespace vault-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace external-secrets-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Adding Helm repositories..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

echo "🔐 Installing Vault..."
helm upgrade --install vault hashicorp/vault \
    --namespace vault-system \
    --set "server.dev.enabled=true" \
    --set "server.dev.devRootToken=root" \
    --set "injector.enabled=false" \
    --wait

echo "🔑 Installing External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
    --namespace external-secrets-system \
    --wait

echo "⏳ Waiting for External Secrets to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=external-secrets -n external-secrets-system --timeout=300s

echo "⏳ Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault-system --timeout=300s

echo "🔧 Configuring Vault secrets..."
VAULT_POD=$(kubectl get pods -n vault-system -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n vault-system $VAULT_POD -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    export VAULT_TOKEN=root && 
    vault secrets enable -path=secret kv-v2 2>/dev/null || echo 'KV engine already enabled' &&
    vault kv put secret/database username=postgres password=postgres
"

echo "🔐 Creating vault token secret..."
kubectl delete secret vault-token -n "$NAMESPACE" --ignore-not-found
kubectl create secret generic vault-token -n "$NAMESPACE" --from-literal=token=root

echo "🚀 Deploying Stanford Students Stack..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --timeout=10m \
    --wait

echo "🔄 Force refreshing ExternalSecrets..."
kubectl annotate externalsecret postgres-credentials -n "$NAMESPACE" force-sync=$(date +%s) --overwrite || true
kubectl annotate externalsecret app-credentials -n "$NAMESPACE" force-sync=$(date +%s) --overwrite || true

echo "⏳ Waiting for secrets to be created..."
for i in {1..30}; do
    if kubectl get secret postgres-secret -n "$NAMESPACE" &>/dev/null && kubectl get secret app-secret -n "$NAMESPACE" &>/dev/null; then
        echo "✅ Secrets created by ExternalSecrets"
        break
    fi
    echo "Waiting for ExternalSecrets to sync... ($i/30)"
    sleep 5
done

echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/postgres -n "$NAMESPACE"

echo "⏳ Waiting for API to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/stanford-api -n "$NAMESPACE"

echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
kubectl get pods -n "$NAMESPACE"
echo ""
kubectl get svc -n "$NAMESPACE"
echo ""
echo "🎉 Stanford Students API is deployed!"
echo "Access: kubectl port-forward -n $NAMESPACE svc/stanford-api-service 8080:8080"
echo "Cleanup: ./cleanup.sh"