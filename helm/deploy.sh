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

echo "[$(date -Iseconds)] 🧹 Cleaning up existing resources..."
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" --ignore-not-found
kubectl delete namespace "$NAMESPACE" --ignore-not-found

echo "[$(date -Iseconds)] 🚀 Deploying Stanford Students Stack Helm chart..."
helm install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --skip-crds \
    --replace \
    --timeout=10m \
    --wait

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
echo "🎉 Access: kubectl port-forward -n $NAMESPACE svc/stanford-api-service 8080:8080"