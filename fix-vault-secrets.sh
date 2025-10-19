#!/bin/bash

set -e

echo "🔧 Fixing Vault Secret Issues..."
echo "================================"

# 1. Check Vault status
echo "1. 📋 Checking Vault status..."
VAULT_POD=$(kubectl get pods -l app=vault -n vault-system -o jsonpath='{.items[0].metadata.name}')
echo "Vault pod: $VAULT_POD"

# 2. Test Vault connectivity
echo "2. 🔗 Testing Vault connectivity..."
kubectl exec -n vault-system $VAULT_POD -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    vault status
"

# 3. Enable KV engine and create secrets
echo "3. 🔐 Setting up Vault secrets..."
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

# 4. Fix vault token secret
echo "4. 🔑 Fixing vault token secret..."
kubectl delete secret vault-token -n student-api --ignore-not-found
kubectl create secret generic vault-token -n student-api --from-literal=token=root

# 5. Force refresh ExternalSecrets
echo "5. 🔄 Force refreshing ExternalSecrets..."
kubectl annotate externalsecret postgres-credentials -n student-api force-sync=$(date +%s) --overwrite || echo "postgres-credentials not found"
kubectl annotate externalsecret app-credentials -n student-api force-sync=$(date +%s) --overwrite || echo "app-credentials not found"

# 6. Wait for secrets to be created by ExternalSecrets
echo "6. ⏳ Waiting for ExternalSecrets to create secrets..."
for i in {1..30}; do
    if kubectl get secret postgres-secret -n student-api &>/dev/null && kubectl get secret app-secret -n student-api &>/dev/null; then
        echo "✅ Both secrets created successfully by ExternalSecrets"
        break
    fi
    echo "Waiting for ExternalSecrets to sync... ($i/30)"
    sleep 5
done

# 7. Check ExternalSecret status if secrets not created
if ! kubectl get secret postgres-secret -n student-api &>/dev/null || ! kubectl get secret app-secret -n student-api &>/dev/null; then
    echo "❌ ExternalSecrets failed to create secrets. Checking status..."
    echo "ExternalSecret postgres-credentials status:"
    kubectl describe externalsecret postgres-credentials -n student-api 2>/dev/null || echo "Not found"
    echo ""
    echo "ExternalSecret app-credentials status:"
    kubectl describe externalsecret app-credentials -n student-api 2>/dev/null || echo "Not found"
    echo ""
    echo "External Secrets Controller logs:"
    kubectl logs -l app=external-secrets-controller -n external-secrets-system --tail=10
    echo ""
    echo "❌ Secrets not created automatically. Please check ExternalSecrets configuration."
    exit 1
fi

# 8. Restart deployments
echo "8. 🔄 Restarting deployments..."
kubectl rollout restart deployment/postgres -n student-api 2>/dev/null || echo "postgres deployment not found"
kubectl rollout restart deployment/stanford-api -n student-api 2>/dev/null || echo "stanford-api deployment not found"

echo "✅ Vault secrets fix complete!"
echo ""
echo "📊 Final status:"
echo "Secrets (created by ExternalSecrets):"
kubectl get secrets -n student-api
echo ""
echo "ExternalSecrets status:"
kubectl get externalsecrets -n student-api
echo ""
echo "Pods:"
kubectl get pods -n student-api