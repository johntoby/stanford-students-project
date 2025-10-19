# Stanford Students API - Helm Charts

This directory contains Helm charts for deploying the Stanford Students API and all its dependencies on Kubernetes.

## Architecture

The deployment consists of:
- **External Secrets Operator**: Manages secrets from HashiCorp Vault
- **HashiCorp Vault**: Secrets management (dev mode)
- **PostgreSQL**: Database for student records
- **Stanford API**: The main REST API application

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- Helm 3.x installed
- kubectl configured to access your cluster

## Quick Start

### 1. Deploy the entire stack:
```bash
cd helm
chmod +x deploy.sh
./deploy.sh
```

### 2. Access the application:
- Frontend: `http://localhost:8080`
- API: `http://localhost:8080/api/v1`
- Health Check: `http://localhost:8080/healthcheck`

### 3. Clean up:
```bash
chmod +x cleanup.sh
./cleanup.sh
```

## Manual Deployment

### Step-by-step deployment:

1. **Update dependencies:**
   ```bash
   cd stanford-students-stack
   helm dependency update
   cd ..
   ```

2. **Deploy the stack:**
   ```bash
   helm install stanford-students-stack ./stanford-students-stack \
     --namespace student-api \
     --create-namespace \
     --wait
   ```

3. **Check deployment status:**
   ```bash
   kubectl get pods -n student-api
   kubectl get pods -n vault-system
   kubectl get pods -n external-secrets-system
   ```

## Individual Chart Deployment

You can also deploy individual components:

```bash
# Deploy External Secrets Operator
helm install external-secrets ./external-secrets

# Deploy Vault
helm install vault ./vault

# Deploy PostgreSQL
helm install postgresql ./postgresql

# Deploy Stanford API
helm install stanford-api ./stanford-api
```

## Configuration

### Customizing Values

Create a custom values file:

```yaml
# custom-values.yaml
stanford-api:
  replicas: 3
  image:
    tag: "v2.0.0"
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"

postgresql:
  persistence:
    size: 5Gi
```

Deploy with custom values:
```bash
helm upgrade --install stanford-students-stack ./stanford-students-stack \
  -f custom-values.yaml \
  --namespace student-api \
  --create-namespace
```

### Environment-specific Deployments

For different environments, create separate values files:

```bash
# Development
helm install stanford-dev ./stanford-students-stack \
  -f values-dev.yaml \
  --namespace student-api-dev

# Production
helm install stanford-prod ./stanford-students-stack \
  -f values-prod.yaml \
  --namespace student-api-prod
```

## Chart Structure

```
helm/
├── stanford-students-stack/     # Umbrella chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── charts/                  # Dependencies
├── external-secrets/            # External Secrets Operator
├── vault/                       # HashiCorp Vault
├── postgresql/                  # PostgreSQL Database
├── stanford-api/                # Stanford API Application
├── deploy.sh                    # Deployment script
├── cleanup.sh                   # Cleanup script
└── README.md                    # This file
```

## Troubleshooting

### Check pod status:
```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
```

### View logs:
```bash
kubectl logs -f deployment/stanford-api -n student-api
kubectl logs -f deployment/postgres -n student-api
kubectl logs -f deployment/vault -n vault-system
```

### Check secrets:
```bash
kubectl get externalsecrets -n student-api
kubectl get secrets -n student-api
```

### Vault setup (if needed):
```bash
# Port forward to Vault
kubectl port-forward svc/vault-service 8200:8200 -n vault-system

# Access Vault UI at http://localhost:8200
# Token: root

# Add database credentials
vault kv put secret/database username=postgres password=postgres
```

## Upgrading

To upgrade the deployment:
```bash
helm upgrade stanford-students-stack ./stanford-students-stack \
  --namespace student-api
```

## Uninstalling

To completely remove the deployment:
```bash
./cleanup.sh
```

Or manually:
```bash
helm uninstall stanford-students-stack -n student-api
kubectl delete namespace student-api vault-system external-secrets-system
```