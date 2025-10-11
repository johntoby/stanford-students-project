#!/bin/bash

set -e  # Exit on any error

echo "🔐 Setting up HashiCorp Vault and External Secrets..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Deploy Vault
echo "📦 Deploying Vault..."
kubectl apply -f k8s/vault.yml

echo "⏳ Waiting for Vault to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/vault -n vault-system

# Deploy External Secrets Operator
echo "🔑 Deploying External Secrets Operator..."
kubectl apply -f k8s/external-secrets.yml

echo "⏳ Waiting for CRDs to be established..."
kubectl wait --for=condition=established --timeout=300s crd/secretstores.external-secrets.io
kubectl wait --for=condition=established --timeout=300s crd/externalsecrets.external-secrets.io

echo "⏳ Waiting for External Secrets to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/external-secrets-controller -n external-secrets-system

# Wait for Vault pod to be running and ready
echo "⏳ Waiting for Vault pod to be ready..."
kubectl wait --for=condition=ready --timeout=300s pod -l app=vault -n vault-system

# Since Vault is running in dev mode, it's already initialized and unsealed
echo "ℹ️ Vault is running in dev mode - already initialized and unsealed"
VAULT_TOKEN="root"



# Enable KV secrets engine if not already enabled
echo "🔧 Enabling KV secrets engine..."
kubectl exec -n vault-system deployment/vault -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    export VAULT_TOKEN=$VAULT_TOKEN && 
    vault secrets enable -path=secret kv-v2 2>/dev/null || echo 'KV engine already enabled'
"

# Configure Vault with secrets
echo "🔧 Configuring Vault with database credentials..."
kubectl exec -n vault-system deployment/vault -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    export VAULT_TOKEN=$VAULT_TOKEN && 
    vault kv put secret/database username=postgres password=postgres
"

echo "✅ Vault and External Secrets setup complete!"
echo "🔐 Vault Token: $VAULT_TOKEN (dev mode)"
echo "⚠️ In production, use proper Vault initialization and unsealing!"