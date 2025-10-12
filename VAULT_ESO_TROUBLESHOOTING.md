# Vault and External Secrets Operator Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: ExternalSecrets Not Creating Kubernetes Secrets

**Symptoms:**
- `postgres-secret` or `app-secret` not found
- Pods failing with "secret not found" errors
- ExternalSecret shows "SecretSyncError" status

**Root Causes:**
1. **Vault Token Authentication Issues**
   - Incorrect base64 encoding of vault token
   - Token secret not in the correct namespace
   - Token doesn't have proper permissions

2. **Vault Connectivity Issues**
   - External Secrets Controller can't reach Vault service
   - Incorrect Vault server URL in SecretStore
   - Network policies blocking communication

3. **Vault Secret Path Issues**
   - Secrets not stored in Vault at expected path
   - Incorrect KV engine version configuration
   - Wrong property names in Vault secret

**Solutions:**

#### Fix 1: Verify and Fix Vault Token
```bash
# Check current token secret
kubectl get secret vault-token -n student-api -o yaml

# Recreate with correct encoding
kubectl delete secret vault-token -n student-api
kubectl create secret generic vault-token -n student-api --from-literal=token=root
```

#### Fix 2: Verify Vault Secrets
```bash
# Check if secrets exist in Vault
kubectl exec -n vault-system deployment/vault -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    export VAULT_TOKEN=root && 
    vault kv get secret/database
"

# If not found, create them
kubectl exec -n vault-system deployment/vault -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    export VAULT_TOKEN=root && 
    vault kv put secret/database username=postgres password=postgres
"
```

#### Fix 3: Test Connectivity
```bash
# Test ESO to Vault connectivity
ESO_POD=$(kubectl get pods -l app=external-secrets-controller -n external-secrets-system -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n external-secrets-system $ESO_POD -- curl -s http://vault-service.vault-system.svc.cluster.local:8200/v1/sys/health
```

### Issue 2: Pods Failing to Start Due to Missing Secrets

**Symptoms:**
- Pods stuck in `CreateContainerConfigError` state
- Error: "secret not found" or "key not found in secret"
- Init containers failing

**Root Causes:**
1. **Race Condition**: Pods starting before ExternalSecrets create the secrets
2. **Missing Secret Keys**: ExternalSecret creates secret but with wrong keys
3. **Secret Not in Correct Namespace**

**Solutions:**

#### Fix 1: Add Init Containers to Wait for Secrets
```yaml
initContainers:
- name: wait-for-secret
  image: busybox:1.35
  command:
  - sh
  - -c
  - |
    echo "Waiting for secrets to be available..."
    while ! [ -f /etc/secrets/POSTGRES_USER ]; do
      echo "Secret not ready, waiting..."
      sleep 5
    done
    echo "Secret is ready!"
  volumeMounts:
  - name: secret-volume
    mountPath: /etc/secrets
```

#### Fix 2: Use Manual Secret Creation as Fallback
```bash
# Create secrets manually if ExternalSecret fails
kubectl create secret generic postgres-secret -n student-api \
    --from-literal=POSTGRES_USER=postgres \
    --from-literal=POSTGRES_PASSWORD=postgres

kubectl create secret generic app-secret -n student-api \
    --from-literal=DB_USER=postgres \
    --from-literal=DB_PASSWORD=postgres
```

### Issue 3: External Secrets Controller Not Working

**Symptoms:**
- ESO controller pod not running
- ESO controller logs show errors
- ExternalSecrets never sync

**Root Causes:**
1. **CRDs Not Installed**: Custom Resource Definitions missing
2. **RBAC Issues**: Service account lacks permissions
3. **Controller Image Issues**: Wrong image version or pull issues

**Solutions:**

#### Fix 1: Reinstall External Secrets Operator
```bash
# Delete existing installation
kubectl delete -f k8s/external-secrets.yml

# Wait a moment
sleep 10

# Reinstall
kubectl apply -f k8s/external-secrets.yml

# Wait for CRDs to be established
kubectl wait --for=condition=established --timeout=300s crd/secretstores.external-secrets.io
kubectl wait --for=condition=established --timeout=300s crd/externalsecrets.external-secrets.io

# Wait for controller to be ready
kubectl wait --for=condition=available --timeout=300s deployment/external-secrets-controller -n external-secrets-system
```

#### Fix 2: Check Controller Logs
```bash
# View controller logs
kubectl logs -f deployment/external-secrets-controller -n external-secrets-system

# Check for common errors:
# - "failed to get secret" - token authentication issue
# - "connection refused" - vault connectivity issue
# - "not found" - vault secret path issue
```

### Issue 4: Vault Not Accessible or Sealed

**Symptoms:**
- Vault pod running but health checks failing
- "Vault is sealed" errors
- Connection timeouts to Vault

**Root Causes:**
1. **Vault Sealed**: Vault needs to be unsealed (shouldn't happen in dev mode)
2. **Vault Not Ready**: Pod running but service not ready
3. **Configuration Issues**: Wrong Vault configuration

**Solutions:**

#### Fix 1: Check Vault Status
```bash
# Check Vault pod status
kubectl get pods -l app=vault -n vault-system

# Check Vault service
kubectl get svc vault-service -n vault-system

# Test Vault directly
kubectl exec -n vault-system deployment/vault -- sh -c "
    export VAULT_ADDR=http://127.0.0.1:8200 && 
    vault status
"
```

#### Fix 2: Restart Vault if Needed
```bash
# Restart Vault deployment
kubectl rollout restart deployment/vault -n vault-system
kubectl rollout status deployment/vault -n vault-system

# Wait for it to be ready
kubectl wait --for=condition=ready --timeout=300s pod -l app=vault -n vault-system
```

## Debugging Commands

### Quick Status Check
```bash
# Check all components
kubectl get pods -n vault-system
kubectl get pods -n external-secrets-system  
kubectl get pods -n student-api

# Check secrets
kubectl get secrets -n student-api
kubectl get externalsecrets -n student-api
kubectl get secretstores -n student-api
```

### Detailed Debugging
```bash
# Run the debug script
chmod +x debug-vault-eso.sh
./debug-vault-eso.sh

# Or run individual checks
kubectl describe externalsecret postgres-credentials -n student-api
kubectl describe secretstore vault-secret-store -n student-api
kubectl logs -l app=external-secrets-controller -n external-secrets-system --tail=50
```

### Force Refresh ExternalSecrets
```bash
# Add annotation to force refresh
kubectl annotate externalsecret postgres-credentials -n student-api force-sync=$(date +%s) --overwrite
kubectl annotate externalsecret app-credentials -n student-api force-sync=$(date +%s) --overwrite
```

## Prevention Best Practices

1. **Always Use Init Containers**: Wait for secrets before starting main containers
2. **Set Proper Resource Limits**: Ensure ESO controller has enough resources
3. **Monitor Secret Sync**: Set up alerts for ExternalSecret sync failures
4. **Use Fallback Secrets**: Have manual secret creation as backup
5. **Test Connectivity**: Regularly test Vault connectivity from ESO
6. **Proper RBAC**: Ensure service accounts have correct permissions
7. **Version Compatibility**: Use compatible versions of Vault and ESO

## Quick Fix Script

Run the comprehensive fix script:
```bash
chmod +x fix-vault-eso.sh
./fix-vault-eso.sh
```

This script will:
1. Verify Vault is properly configured
2. Ensure ESO is running correctly
3. Fix SecretStore and ExternalSecret configurations
4. Create fallback secrets if needed
5. Restart deployments to pick up new secrets
6. Verify everything is working

## Emergency Fallback

If all else fails, use manual secrets:
```bash
# Delete problematic ExternalSecrets
kubectl delete externalsecret postgres-credentials app-credentials -n student-api

# Create manual secrets
kubectl create secret generic postgres-secret -n student-api \
    --from-literal=POSTGRES_USER=postgres \
    --from-literal=POSTGRES_PASSWORD=postgres

kubectl create secret generic app-secret -n student-api \
    --from-literal=DB_USER=postgres \
    --from-literal=DB_PASSWORD=postgres

# Restart deployments
kubectl rollout restart deployment/postgres -n student-api
kubectl rollout restart deployment/stanford-api -n student-api
```