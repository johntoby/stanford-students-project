# ArgoCD Setup for Stanford Students Project

## Prerequisites
- Kubernetes cluster running
- kubectl configured
- Helm 3.x installed

## Installation Steps

### 1. Install ArgoCD
```bash
# Create namespace
kubectl apply -f argocd/namespace.yaml

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply node selector configuration
kubectl apply -f argocd/install.yaml

# Patch argocd-server deployment for node selector
kubectl patch deployment argocd-server -n argocd -p '{"spec":{"template":{"spec":{"nodeSelector":{"type":"dependent_services"}}}}}'
```

### 2. Setup Repository and Application
```bash
# Update repository URL in argocd/repository.yaml
# Replace 'your-username' with actual GitHub username

# Apply repository secret
kubectl apply -f argocd/repository.yaml

# Apply application
kubectl apply -f argocd/application.yaml
```

### 3. Access ArgoCD UI
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Access at http://localhost:8080
# Username: admin
# Password: (from step above)
```

### 4. Configure Self-Hosted Runner
Ensure your self-hosted GitHub runner has:
- kubectl access to the cluster
- Git configured
- Proper permissions to push to repository

## Auto-Sync Behavior
- ArgoCD monitors the helm/stanford-students-stack directory
- When GitHub Actions updates values.yaml with new image tags, ArgoCD auto-syncs
- Applications are automatically deployed with latest images