#!/bin/bash

echo "🧹 Cleaning up Stanford Students API from Kubernetes..."

echo "🗑️ Deleting Application..."
kubectl delete -f k8s/application.yml --ignore-not-found=true

echo "🗑️ Deleting Database..."
kubectl delete -f k8s/database.yml --ignore-not-found=true

echo "🗑️ Deleting External Secrets..."
kubectl delete -f k8s/external-secrets.yml --ignore-not-found=true

echo "🗑️ Deleting Vault..."
kubectl delete -f k8s/vault.yml --ignore-not-found=true

echo "✅ Cleanup complete!"