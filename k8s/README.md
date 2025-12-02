# Kubernetes Deployment - Stanford Students API

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   vault-system namespace                    │
│  ┌─────────────┐    ┌─────────────┐                       │
│  │   Service   │    │  Vault Pod  │                       │
│  │ (ClusterIP) │    │             │                       │
│  └─────────────┘    └─────────────┘                       │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│              external-secrets-system namespace              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            External Secrets Controller             │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     student-api namespace                   │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │  Service    │    │  API Pod 1  │    │  API Pod 2  │    │
│  │ (ClusterIP) │    │             │    │             │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│                                │                           │
│                                ▼                           │
│  ┌─────────────┐    ┌─────────────┐                       │
│  │  Service    │    │Postgres Pod │                       │
│  │ (ClusterIP) │    │    + PVC    │                       │
│  └─────────────┘    └─────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Vault (`vault.yml`)
- **Namespace**: `vault-system`
- **Components**: Namespace, ServiceAccount, ConfigMap, Deployment, Service
- **Features**: HashiCorp Vault for secret management

### 2. External Secrets (`external-secrets.yml`)
- **Namespace**: `external-secrets-system`
- **Components**: Namespace, ServiceAccount, RBAC, Deployment
- **Features**: External Secrets Operator for Vault integration

### 3. Database (`database.yml`)
- **Namespace**: `student-api`
- **Components**: Namespace, ConfigMap, SecretStore, ExternalSecret, PVC, Deployment, Service
- **Features**: PostgreSQL with External Secrets integration

### 4. Application (`application.yml`)
- **Namespace**: `student-api`
- **Components**: ConfigMap, ExternalSecret, Deployment, Service
- **Features**: 2 replicas with init container for DB migrations

## Quick Deployment

```bash
# Deploy everything now
./k8s/deploy.sh

# Check status
kubectl get pods -n vault-system
kubectl get pods -n external-secrets-system
kubectl get pods -n student-api

# Access application
kubectl port-forward service/stanford-api-service 8080:8080 -n student-api
curl http://localhost:8080/healthcheck

# Cleanup
./k8s/cleanup.sh
```

## Manual Deployment

```bash
# Build image
docker build -t stanford-students-api:latest .

# Setup Vault and External Secrets
./k8s/setup-vault.sh

# Deploy in order
kubectl apply -f k8s/database.yml
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n student-api

kubectl apply -f k8s/application.yml
kubectl wait --for=condition=available --timeout=300s deployment/stanford-api -n student-api
```

## Key Features

✅ **HashiCorp Vault Integration**: Secure secret management  
✅ **External Secrets Operator**: Automated secret synchronization  
✅ **ConfigMaps for Environment Variables**: Non-sensitive configuration  
✅ **ClusterIP Services**: Internal cluster communication only  
✅ **2 API Replicas**: High availability without external load balancer  
✅ **Init Container Migrations**: DB migrations run before app starts  
✅ **Persistent Storage**: PostgreSQL with PVC  

## Access Points

- **Port Forward**: `kubectl port-forward service/stanford-api-service 8080:8080 -n student-api`
- **Then access**: `http://localhost:8080`