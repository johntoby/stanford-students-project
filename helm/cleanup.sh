#!/bin/bash

echo "🧹 Cleaning up Stanford Students Stack..."

# Uninstall the Helm release
helm uninstall stanford-students-stack -n student-api || true

# Delete namespaces
kubectl delete namespace student-api --ignore-not-found=true
kubectl delete namespace vault-system --ignore-not-found=true
kubectl delete namespace external-secrets-system --ignore-not-found=true

# Delete CRDs
kubectl delete crd secretstores.external-secrets.io --ignore-not-found=true
kubectl delete crd externalsecrets.external-secrets.io --ignore-not-found=true

echo "✅ Cleanup completed!" Enjoy