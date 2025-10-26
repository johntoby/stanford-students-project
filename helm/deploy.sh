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

echo "[$(date -Iseconds)] 📦 Adding Helm repositories..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

echo "[$(date -Iseconds)] 📁 Creating namespaces..."
# Create namespaces BEFORE installing Helm charts
kubectl create namespace vault-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace external-secrets-system --dry-run=client -o yaml | kubectl apply -f -
# Don't create student-api namespace here - let your chart handle it

echo "[$(date -Iseconds)] 🔐 Installing Vault (dev mode for testing)..."
helm upgrade --install vault hashicorp/vault \
    --namespace vault-system \
    --create-namespace \
    --set "server.dev.enabled=true" \
    --set "server.dev.devRootToken=root" \
    --set "injector.enabled=false" \
    --wait \
    --timeout=5m

echo "[$(date -Iseconds)] 🔑 Installing External Secrets Operator (installCRDs=true)..."
helm upgrade --install external-secrets external-secrets/external-secrets \
    --namespace external-secrets-system \
    --create-namespace \
    --set installCRDs=true \
    --wait \
    --timeout=5m

echo "[$(date -Iseconds)] ⏳ Waiting for External Secrets pods to be ready..."
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=external-secrets \
    -n external-secrets-system \
    --timeout=300s

echo "[$(date -Iseconds)] ⏳ Waiting for External Secrets CRDs to be created and established..."
for crd_name in externalsecrets.external-secrets.io secretstores.external-secrets.io clustersecretstores.external-secrets.io; do
    echo "[$(date -Iseconds)] → ensuring CRD ${crd_name} exists..."
    for i in {1..30}; do
        if kubectl get crd ${crd_name} &>/dev/null; then
            echo "[$(date -Iseconds)] CRD ${crd_name} found."
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ Timeout waiting for CRD ${crd_name}"
            exit 1
        fi
        sleep 2
    done
    
    echo "[$(date -Iseconds)] → waiting for CRD ${crd_name} to become Established..."
    kubectl wait --for condition=established --timeout=120s crd/${crd_name}
done

echo "[$(date -Iseconds)] ⏳ Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault-system --timeout=300s

echo "[$(date -Iseconds)] 🔧 Configuring Vault secrets..."
VAULT_POD=$(kubectl get pods -n vault-system -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n vault-system $VAULT_POD -- sh -c '
    export VAULT_ADDR=http://127.0.0.1:8200
    export VAULT_TOKEN=root
    
    # Enable KV v2 secrets engine
    vault secrets enable -path=secret kv-v2 2>/dev/null || echo "KV engine already enabled"
    
    # Store database credentials
    vault kv put secret/database username=postgres password=postgres
    
    # Verify
    vault kv get secret/database
'

echo "[$(date -Iseconds)] 🚀 Deploying Stanford Students Stack Helm chart..."
# Deploy your application chart
# It should only create student-api namespace and resources in it
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --skip-crds \
    --timeout=10m \
    --wait

echo "[$(date -Iseconds)] 🔐 Creating vault token secret for ExternalSecrets..."
kubectl delete secret vault-token -n "$NAMESPACE" --ignore-not-found
kubectl create secret generic vault-token -n "$NAMESPACE" --from-literal=token=root

echo "[$(date -Iseconds)] ⏳ Checking ExternalSecret resources..."
kubectl get externalsecret -n "$NAMESPACE" || echo "No ExternalSecrets found yet"
kubectl get secretstore -n "$NAMESPACE" || echo "No SecretStores found yet"

echo "[$(date -Iseconds)] 🔄 Triggering ExternalSecrets sync..."
sleep 5
kubectl annotate externalsecret --all -n "$NAMESPACE" force-sync=$(date +%s) --overwrite || true

echo "[$(date -Iseconds)] ⏳ Waiting for secrets to be created..."
for i in {1..60}; do
    POSTGRES_SECRET=$(kubectl get secret postgres-secret -n "$NAMESPACE" 2>/dev/null && echo "✓" || echo "✗")
    APP_SECRET=$(kubectl get secret app-secret -n "$NAMESPACE" 2>/dev/null && echo "✓" || echo "✗")
    
    if [ "$POSTGRES_SECRET" = "✓" ] && [ "$APP_SECRET" = "✓" ]; then
        echo "[$(date -Iseconds)] ✅ All secrets created"
        break
    fi
    
    if [ $i -eq 60 ]; then
        echo "⚠️  Secrets not ready within timeout"
        kubectl describe externalsecret -n "$NAMESPACE"
    fi
    
    echo "Waiting... postgres: $POSTGRES_SECRET, app: $APP_SECRET ($i/60)"
    sleep 3
done

echo "[$(date -Iseconds)] ⏳ Waiting for deployments..."
kubectl wait --for=condition=available --timeout=180s deployment/postgres -n "$NAMESPACE" || true
kubectl wait --for=condition=available --timeout=300s deployment/stanford-api -n "$NAMESPACE" || true

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
kubectl get pods -n "$NAMESPACE"
echo ""
kubectl get svc -n "$NAMESPACE"
echo ""
echo "🎉 API Access: kubectl port-forward -n $NAMESPACE svc/stanford-api-service 8080:8080"