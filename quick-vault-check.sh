#!/bin/bash

echo "🔍 Quick Vault Status Check..."
echo "=============================="

# Check Vault pod
echo "1. Vault Pod Status:"
kubectl get pods -l app=vault -n vault-system

# Check if Vault has secrets
echo ""
echo "2. Checking Vault Secrets:"
VAULT_POD=$(kubectl get pods -l app=vault -n vault-system -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n vault-system $VAULT_POD -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    export VAULT_TOKEN=root && 
    vault kv get secret/database 2>/dev/null || echo 'No database secrets found'
"

# Check Kubernetes secrets
echo ""
echo "3. Kubernetes Secrets Status:"
kubectl get secrets -n student-api | grep -E "(postgres-secret|app-secret|vault-token)" || echo "No secrets found"

# Check ExternalSecrets status
echo ""
echo "4. ExternalSecrets Status:"
kubectl get externalsecrets -n student-api 2>/dev/null || echo "No ExternalSecrets found"

# Check pod status
echo ""
echo "5. Application Pods:"
kubectl get pods -n student-api