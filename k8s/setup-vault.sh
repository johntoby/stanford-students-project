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

# Initialize Vault if not already initialized
echo "🔍 Checking Vault initialization status..."
VAULT_STATUS=$(kubectl exec -n vault-system deployment/vault -- vault status -format=json 2>/dev/null || echo '{"initialized":false}')

if echo "$VAULT_STATUS" | grep -q '"initialized":false'; then
    echo "🔧 Initializing Vault..."
    INIT_OUTPUT=$(kubectl exec -n vault-system deployment/vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json)
    UNSEAL_KEY=$(echo "$INIT_OUTPUT" | grep -o '"unseal_keys_b64":\["[^"]*"' | cut -d'"' -f4)
    ROOT_TOKEN=$(echo "$INIT_OUTPUT" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
    echo "📝 Vault initialized successfully"
else
    echo "ℹ️ Vault already initialized"
fi

# Check if Vault is sealed and unseal if needed
VAULT_STATUS=$(kubectl exec -n vault-system deployment/vault -- vault status -format=json 2>/dev/null || echo '{"sealed":true}')
if echo "$VAULT_STATUS" | grep -q '"sealed":true'; then
    if [ -n "$UNSEAL_KEY" ]; then
        echo "🔓 Vault is sealed, unsealing with generated key..."
        kubectl exec -n vault-system deployment/vault -- vault operator unseal "$UNSEAL_KEY"
    else
        echo "⚠️ Vault is sealed but no unseal key available. Manual unsealing required."
    fi
else
    echo "✅ Vault is already unsealed"
fi

# Use root token from initialization or default
VAULT_TOKEN=${ROOT_TOKEN:-"root"}

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
if [ -n "$UNSEAL_KEY" ]; then
    echo "🔑 Unseal Key: $UNSEAL_KEY"
    echo "🔐 Root Token: $ROOT_TOKEN"
    echo "⚠️ Store these credentials securely!"
fi