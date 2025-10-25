#!/bin/bash

set -euo pipefail

echo "🚀 Starting Stanford Students API Helm deployment..."

# Configuration
NAMESPACE="student-api"
RELEASE_NAME="stanford-students-stack"
CHART_PATH="./stanford-students-stack"
EXTERNAL_SECRETS_NS="external-secrets-system"
VAULT_NS="vault-system"

# Helpers
log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"; }

# Check prerequisites
log "🔍 Checking prerequisites..."
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

log "📁 Creating namespaces (idempotent)..."
kubectl create namespace "$VAULT_NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$EXTERNAL_SECRETS_NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

log "📦 Adding Helm repositories..."
helm repo add hashicorp https://helm.releases.hashicorp.com || true
helm repo add external-secrets https://charts.external-secrets.io || true
helm repo update

log "🔐 Installing Vault (dev mode for testing)..."
helm upgrade --install vault hashicorp/vault \
    --namespace "$VAULT_NS" \
    --set "server.dev.enabled=true" \
    --set "server.dev.devRootToken=root" \
    --set "injector.enabled=false" \
    --wait

log "🔑 Installing External Secrets Operator (installCRDs=true)..."
# Important: ensure CRDs are installed as part of the chart to avoid race conditions.
helm upgrade --install external-secrets external-secrets/external-secrets \
    --namespace "$EXTERNAL_SECRETS_NS" \
    --set installCRDs=true \
    --wait

# Wait for the External Secrets pods to be ready (use the release label if present)
log "⏳ Waiting for External Secrets pods to be ready..."
# Chart uses app.kubernetes.io/name=external-secrets (best-effort); fallback to release label
if ! kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=external-secrets -n "$EXTERNAL_SECRETS_NS" --timeout=180s 2>/dev/null; then
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=external-secrets -n "$EXTERNAL_SECRETS_NS" --timeout=180s
fi

# Robust CRD check: poll until CRDs appear, then wait for Established
CRDS_TO_WAIT=(
  "externalsecrets.external-secrets.io"
  "secretstores.external-secrets.io"
  "clustersecretstores.external-secrets.io"
)

log "⏳ Waiting for External Secrets CRDs to be created and established..."
# wait up to 300s for CRDs to appear
CRD_APPEAR_TIMEOUT=300
CRD_APPEAR_POLL_INTERVAL=3
start_ts=$(date +%s)

for crd in "${CRDS_TO_WAIT[@]}"; do
  log "→ ensuring CRD ${crd} exists..."
  while true; do
    if kubectl get crd "$crd" &>/dev/null; then
      log "CRD ${crd} found."
      break
    fi
    now_ts=$(date +%s)
    elapsed=$((now_ts - start_ts))
    if [ "$elapsed" -ge "$CRD_APPEAR_TIMEOUT" ]; then
      echo "❌ Timeout waiting for CRD ${crd} to appear (waited ${CRD_APPEAR_TIMEOUT}s)."
      kubectl get crd || true
      exit 1
    fi
    sleep $CRD_APPEAR_POLL_INTERVAL
  done

  # Once present, wait for Established condition
  log "→ waiting for CRD ${crd} to become Established..."
  kubectl wait --for=condition=established --timeout=180s "crd/$crd"
done

log "⏳ Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n "$VAULT_NS" --timeout=300s

log "🔧 Configuring Vault secrets..."
VAULT_POD=$(kubectl get pods -n "$VAULT_NS" -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n "$VAULT_NS" "$VAULT_POD" -- sh -c '
  export VAULT_ADDR=http://127.0.0.1:8200
  export VAULT_TOKEN=root
  if ! vault secrets list | grep -q "secret/"; then
    vault secrets enable -path=secret kv-v2 || true
  fi
  vault kv put secret/database username=postgres password=postgres || true
'

log "🔐 Creating vault token secret in namespace $NAMESPACE..."
kubectl delete secret vault-token -n "$NAMESPACE" --ignore-not-found
kubectl create secret generic vault-token -n "$NAMESPACE" --from-literal=token=root

log "🚀 Deploying Stanford Students Stack Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --timeout=10m \
    --wait

# If your chart creates ExternalSecret resources named like these, annotate to force sync
log "🔄 Force refreshing ExternalSecrets (if present)..."
kubectl annotate externalsecret postgres-credentials -n "$NAMESPACE" force-sync="$(date +%s)" --overwrite 2>/dev/null || true
kubectl annotate externalsecret app-credentials -n "$NAMESPACE" force-sync="$(date +%s)" --overwrite 2>/dev/null || true
# older versions may use 'es' shorthand; try that too (no-fail)
kubectl annotate es postgres-credentials -n "$NAMESPACE" force-sync="$(date +%s)" --overwrite 2>/dev/null || true
kubectl annotate es app-credentials -n "$NAMESPACE" force-sync="$(date +%s)" --overwrite 2>/dev/null || true

log "⏳ Waiting for secrets to be created by ExternalSecrets..."
for i in {1..30}; do
    if kubectl get secret postgres-secret -n "$NAMESPACE" &>/dev/null && kubectl get secret app-secret -n "$NAMESPACE" &>/dev/null; then
        log "✅ Secrets created by ExternalSecrets"
        break
    fi
    log "Waiting for ExternalSecrets to sync... ($i/30)"
    sleep 5
done


log "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/postgres -n "$NAMESPACE" || true

log "⏳ Waiting for API to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/stanford-api -n "$NAMESPACE" || true

log "✅ Deployment complete!"
echo ""
log "📊 Status:"
kubectl get pods -n "$NAMESPACE" || true
echo ""
kubectl get svc -n "$NAMESPACE" || true
echo ""
log "🎉 Stanford Students API is deployed!"
log "Access: kubectl port-forward -n $NAMESPACE svc/stanford-api-service 8080:8080"
log "Cleanup: ./cleanup.sh"
