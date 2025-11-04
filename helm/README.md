# Stanford Students API - Helm Chart

This directory contains the Helm chart for deploying the Stanford Students API with all its dependencies including PostgreSQL, Vault, and External Secrets Operator.

## Quick Start

### Prerequisites
- Kubernetes cluster (minikube, kind, or cloud provider)
- Helm 3.x installed
- kubectl configured to access your cluster

### One-Click Deployment
```bash
cd helm
chmod +x deploy.sh
./deploy.sh
```

### One-Click Cleanup
```bash
cd helm
chmod +x cleanup.sh
./cleanup.sh
```

## Manual Deployment

### 1. Add Required Repositories
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

### 2. Update Dependencies
```bash
cd stanford-students-stack
helm dependency update
cd ..
```

### 3. Deploy the Stack
```bash
helm install stanford-students-stack ./stanford-students-stack \
  --namespace student-api \
  --create-namespace \
  --wait
```

### 4. Setup Vault Secrets
```bash
# Wait for Vault to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault-system --timeout=300s

# Get Vault pod name
VAULT_POD=$(kubectl get pods -n vault-system -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')

# Configure secrets
kubectl exec -n vault-system $VAULT_POD -- vault auth -method=token token=root
kubectl exec -n vault-system $VAULT_POD -- vault kv put secret/database username=postgres password=postgres
```

## Chart Structure

```
stanford-students-stack/
├── Chart.yaml              # Chart metadata and dependencies
├── values.yaml             # Default configuration values
├── charts/                 # Dependency charts (auto-generated)
└── templates/
    ├── _helpers.tpl        # Template helpers
    ├── namespace.yaml      # Main namespace
    ├── vault-namespace.yaml # Vault namespace
    ├── configmap.yaml      # Configuration maps
    ├── secrets.yaml        # External secrets configuration
    ├── postgres.yaml       # PostgreSQL deployment
    └── application.yaml    # Main application deployment
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Main application namespace | `student-api` |
| `app.image.repository` | Application image repository | `johntoby/stanford-students-api` |
| `app.image.tag` | Application image tag | `latest` |
| `app.replicas` | Number of application replicas | `2` |
| `vault.enabled` | Enable Vault deployment | `true` |
| `external-secrets.enabled` | Enable External Secrets Operator | `true` |

### Custom Values File
Create a custom values file to override defaults:

```yaml
# custom-values.yaml
app:
  replicas: 3
  image:
    tag: "v1.2.0"
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
```

Deploy with custom values:
```bash
helm install stanford-students-stack ./stanford-students-stack \
  --namespace student-api \
  --create-namespace \
  --values custom-values.yaml
```

## Accessing the Application

### Port Forward
```bash
kubectl port-forward -n student-api svc/stanford-api-service 8080:8080
```

Then visit: http://localhost:8080

### Using LoadBalancer (Cloud environments)
Update the service type in values.yaml:
```yaml
app:
  service:
    type: LoadBalancer
```

## Monitoring and Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n student-api
```

### View Logs
```bash
# Application logs
kubectl logs -n student-api -l app=stanford-api -f

# Database logs
kubectl logs -n student-api -l app=postgres -f

# Vault logs
kubectl logs -n vault-system -l app.kubernetes.io/name=vault -f
```

### Debug External Secrets
```bash
kubectl get externalsecrets -n student-api
kubectl describe externalsecret app-credentials -n student-api
```

## Upgrading

```bash
helm upgrade stanford-students-stack ./stanford-students-stack \
  --namespace student-api
```

## Uninstalling

### Using Cleanup Script
```bash
./cleanup.sh
```

### Manual Cleanup
```bash
helm uninstall stanford-students-stack -n student-api
kubectl delete namespace student-api
kubectl delete namespace vault-system
kubectl delete namespace external-secrets-system
```

## Dependencies

This chart includes the following dependencies:
- **PostgreSQL**: Database (custom deployment, not using Bitnami chart)
- **Vault**: Secret management (HashiCorp Helm chart)
- **External Secrets Operator**: Secret synchronization (External Secrets Helm chart)

## Security Notes

- Vault is deployed in development mode with a static root token
- For production, configure Vault with proper authentication and TLS
- Database credentials are managed through Vault and External Secrets
- All secrets are automatically rotated based on the refresh interval

  ## Next steps

  Next steps is to Add ArgoCD for GitOps deployment

## Support

For issues and questions:
1. Check the pod logs for error messages
2. Verify all dependencies are properly installed
3. Ensure your Kubernetes cluster has sufficient resources
4. Check the External Secrets Operator logs for secret synchronization issues
