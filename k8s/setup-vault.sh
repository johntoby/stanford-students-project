#!/bin/bash

echo "🔐 Setting up HashiCorp Vault and External Secrets..."

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

# Wait a bit for Vault to fully initialize
echo "⏳ Waiting for Vault to initialize..."
sleep 10

# Configure Vault with secrets
echo "🔧 Configuring Vault with database credentials..."
kubectl exec -n vault-system deployment/vault -- sh -c "export VAULT_TOKEN=root && vault kv put secret/database username=postgres password=postgres"

echo "✅ Vault and External Secrets setup complete!"