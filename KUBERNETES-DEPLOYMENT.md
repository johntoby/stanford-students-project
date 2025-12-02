# Kubernetes Deployment Guide - Stanford Students API

## 🎯 Stage 7 Solution: Deploy REST API and Dependencies in Kubernetes

This guide provides the complete solution for deploying the Stanford Students API with PostgreSQL database and Nginx load balancer in Kubernetes for high availability deployments. 

## 📋 Prerequisites

### Required Tools
- **Kubernetes Cluster** (minikube, kind, Docker Desktop, or cloud provider)
- **kubectl** (configured to access your cluster)
- **Docker** (for building images)
- **Make** (optional, for using Makefile commands)

### Verify Prerequisites
```bash
# Check kubectl
kubectl version --client

# Check Docker
docker --version

# Check cluster access
kubectl cluster-info
```

## 🏗️ Architecture Overview

```
Internet → Ingress → Nginx (Load Balancer) → API Pods (2 replicas) → PostgreSQL
```

### Components:
1. **PostgreSQL**: Database with persistent storage
2. **Stanford API**: REST API with 2 replicas for high availability
3. **Nginx**: Load balancer distributing traffic between API replicas
4. **Ingress**: External access point

## 🚀 Quick Deployment

### Option 1: Using Deployment Script (Recommended)
```bash
# Navigate to project directory
cd stanford-students-project

# Make script executable (Linux/Mac)
chmod +x k8s/deploy.sh

# Deploy everything
./k8s/deploy.sh
```

### Option 2: Using Makefile
```bash
# Navigate to k8s directory
cd k8s

# Deploy everything
make deploy

# Check status
make status
```

### Option 3: Manual Step-by-Step
```bash
# 1. Build Docker image
docker build -t stanford-students-api:latest .

# 2. Apply manifests in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/app-configmap.yaml
kubectl apply -f k8s/nginx-configmap.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml

# 3. Wait for PostgreSQL
kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment -n stanford-students

# 4. Deploy API
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml

# 5. Wait for API
kubectl wait --for=condition=available --timeout=300s deployment/stanford-api-deployment -n stanford-students

# 6. Deploy Nginx and Ingress
kubectl apply -f k8s/nginx-deployment.yaml
kubectl apply -f k8s/nginx-service.yaml
kubectl apply -f k8s/ingress.yaml
```

## 🔍 Verification

### Check Deployment Status
```bash
# Check all pods
kubectl get pods -n stanford-students

# Check services
kubectl get services -n stanford-students

# Check deployments
kubectl get deployments -n stanford-students
```

Expected output:
```
NAME                                    READY   STATUS    RESTARTS   AGE
nginx-deployment-xxx                    1/1     Running   0          2m
postgres-deployment-xxx                 1/1     Running   0          3m
stanford-api-deployment-xxx             1/1     Running   0          2m
stanford-api-deployment-yyy             1/1     Running   0          2m
```

### Test API Endpoints
```bash
# Health check
curl http://localhost:30080/healthcheck

# Get students
curl http://localhost:30080/api/v1/students

# Create a student
curl -X POST http://localhost:30080/api/v1/students \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@stanford.edu","age":20}'
```

## 🌐 Access Methods

### 1. NodePort (Default - Port 30080)
```bash
# Direct access via NodePort
curl http://localhost:30080/healthcheck

# Web interface
open http://localhost:30080
```

### 2. Port Forward (Development)
```bash
# Forward nginx service to local port 8080
kubectl port-forward service/nginx-service 8080:80 -n stanford-students

# Access via localhost:8080
curl http://localhost:8080/healthcheck
```

### 3. Ingress (Production-like)
```bash
# Add to hosts file
echo "127.0.0.1 stanford-students.local" >> /etc/hosts

# Access via domain
curl http://stanford-students.local/healthcheck
```

## 📊 Monitoring and Logs

### View Logs
```bash
# API logs
kubectl logs -f deployment/stanford-api-deployment -n stanford-students

# Nginx logs
kubectl logs -f deployment/nginx-deployment -n stanford-students

# PostgreSQL logs
kubectl logs -f deployment/postgres-deployment -n stanford-students

# All logs (using Makefile)
cd k8s && make logs
```

### Monitor Resources
```bash
# Watch pods
kubectl get pods -n stanford-students -w

# Resource usage
kubectl top pods -n stanford-students

# Events
kubectl get events -n stanford-students --sort-by='.lastTimestamp'
```

## ⚖️ Scaling

### Scale API Replicas
```bash
# Scale to 3 replicas
kubectl scale deployment stanford-api-deployment --replicas=3 -n stanford-students

# Using Makefile
cd k8s && make scale REPLICAS=3

# Verify scaling
kubectl get pods -n stanford-students
```

## 🔧 Configuration Management

### Environment Variables
Configuration is managed through:
- **ConfigMap** (`app-configmap.yaml`): Non-sensitive config
- **Secret** (`postgres-secret.yaml`): Database credentials

### Update Configuration
```bash
# Edit ConfigMap
kubectl edit configmap app-config -n stanford-students

# Restart deployments to pick up changes
kubectl rollout restart deployment/stanford-api-deployment -n stanford-students
```

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n stanford-students

# Check logs
kubectl logs <pod-name> -n stanford-students
```

#### 2. Database Connection Issues
```bash
# Verify PostgreSQL is running
kubectl get pods -n stanford-students | grep postgres

# Check PostgreSQL logs
kubectl logs deployment/postgres-deployment -n stanford-students

# Test database connection from API pod
kubectl exec -it deployment/stanford-api-deployment -n stanford-students -- /bin/sh
```

#### 3. Image Pull Errors (Minikube)
```bash
# Use minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild image
docker build -t stanford-students-api:latest .
```

#### 4. Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n stanford-students

# Verify service configuration
kubectl describe service nginx-service -n stanford-students
```

### Debug Commands
```bash
# Get all resources
kubectl get all -n stanford-students

# Describe problematic resource
kubectl describe <resource-type> <resource-name> -n stanford-students

# Execute into pod for debugging
kubectl exec -it <pod-name> -n stanford-students -- /bin/sh

# Port forward for direct access
kubectl port-forward <pod-name> 8080:8080 -n stanford-students
```

## 🧹 Cleanup

### Remove Everything
```bash
# Using cleanup script
./k8s/cleanup.sh

# Using Makefile
cd k8s && make cleanup

# Manual cleanup
kubectl delete namespace stanford-students
```

## 📁 File Structure

```
k8s/
├── namespace.yaml              # Namespace definition
├── postgres-secret.yaml        # Database credentials
├── postgres-pvc.yaml          # Persistent volume claim
├── postgres-deployment.yaml    # PostgreSQL deployment
├── postgres-service.yaml      # PostgreSQL service
├── app-configmap.yaml         # Application configuration
├── app-deployment.yaml        # API deployment (2 replicas)
├── app-service.yaml           # API service
├── nginx-configmap.yaml       # Nginx configuration
├── nginx-deployment.yaml      # Nginx deployment
├── nginx-service.yaml         # Nginx service (NodePort)
├── ingress.yaml               # Ingress for external access
├── deploy.sh                  # Deployment script
├── cleanup.sh                 # Cleanup script
├── status.sh                  # Status check script
├── Makefile                   # Make commands
└── README.md                  # Detailed documentation
```

## 🎯 Stage 7 Requirements Checklist

✅ **Deploy REST API in Kubernetes**
- API deployed with 2 replicas for high availability
- Proper resource limits and health checks
- ConfigMap and Secret for configuration management

✅ **Deploy PostgreSQL Database**
- PostgreSQL deployed with persistent storage
- Proper credentials management via Secrets
- Health checks and readiness probes

✅ **Load Balancer (Nginx)**
- Nginx deployed as load balancer
- Distributes traffic between API replicas
- Proper configuration via ConfigMap

✅ **External Access**
- NodePort service for direct access (port 30080)
- Ingress for domain-based access
- Port forwarding option for development

✅ **High Availability**
- Multiple API replicas
- Proper pod distribution
- Health checks and auto-restart

✅ **Monitoring and Logging**
- Comprehensive logging setup
- Status monitoring scripts
- Resource monitoring capabilities

✅ **Easy Deployment**
- Automated deployment scripts
- Makefile for common operations
- Step-by-step manual instructions

## 🚀 Next Steps

1. **Production Hardening**:
   - Add network policies
   - Implement RBAC
   - Add SSL/TLS certificates
   - Set up monitoring (Prometheus/Grafana)

2. **CI/CD Integration**:
   - Automate deployments
   - Add testing pipelines
   - Implement GitOps

3. **Scaling**:
   - Horizontal Pod Autoscaler
   - Cluster autoscaling
   - Multi-zone deployment

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review pod logs and events
3. Verify cluster resources and permissions
4. Ensure all prerequisites are met

---

**Congratulations! 🎉** You have successfully completed Stage 7 of the SRE Bootcamp by deploying a complete REST API application with its dependencies in Kubernetes!