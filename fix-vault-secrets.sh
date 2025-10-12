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

# 6. Wait for secrets to be created
echo "6. ⏳ Waiting for secrets to be created..."
for i in {1..20}; do
    if kubectl get secret postgres-secret -n student-api &>/dev/null && kubectl get secret app-secret -n student-api &>/dev/null; then
        echo "✅ Both secrets created successfully"
        break
    fi
    echo "Waiting for secrets... ($i/20)"
    sleep 3
done

# 7. Create manual fallback if ExternalSecrets fail
if ! kubectl get secret postgres-secret -n student-api &>/dev/null; then
    echo "⚠️ Creating postgres-secret manually..."
    kubectl create secret generic postgres-secret -n student-api \
        --from-literal=POSTGRES_USER=postgres \
        --from-literal=POSTGRES_PASSWORD=postgres
fi

if ! kubectl get secret app-secret -n student-api &>/dev/null; then
    echo "⚠️ Creating app-secret manually..."
    kubectl create secret generic app-secret -n student-api \
        --from-literal=DB_USER=postgres \
        --from-literal=DB_PASSWORD=postgres
fi

# 8. Restart deployments
echo "8. 🔄 Restarting deployments..."
kubectl rollout restart deployment/postgres -n student-api 2>/dev/null || echo "postgres deployment not found"
kubectl rollout restart deployment/stanford-api -n student-api 2>/dev/null || echo "stanford-api deployment not found"

echo "✅ Vault secrets fix complete!"
echo ""
echo "📊 Final status:"
kubectl get secrets -n student-api
kubectl get pods -n student-api