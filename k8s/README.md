# Kubernetes Infrastructure Manifests

## Overview

This directory contains Kubernetes manifests for deploying the core infrastructure components of the DevPets system. These manifests define the Jenkins CI/CD platform, PostgreSQL database, and MailHog email testing service.

## Directory Structure

```
k8s/
├── jenkins/                    # Jenkins CI/CD platform
│   ├── jenkins-deployment.yaml # Jenkins deployment
│   ├── jenkins-service.yaml    # Jenkins service
│   ├── jenkins-pvc.yaml        # Jenkins persistent volume claim
│   ├── jenkins-rbac.yaml       # Jenkins RBAC configuration
│   └── Dockerfile              # Jenkins custom image
├── postgres/                   # PostgreSQL database
│   ├── postgres-deployment.yaml # PostgreSQL deployment
│   ├── postgres-service.yaml   # PostgreSQL service
│   ├── postgres-pvc.yaml       # PostgreSQL persistent volume claim
│   ├── postgres-secret.yaml    # Database credentials
│   └── Dockerfile              # PostgreSQL custom image
├── mailhog/                    # MailHog email testing
│   ├── mailhog-deployment.yaml # MailHog deployment
│   ├── mailhog-service.yaml    # MailHog service
│   └── Dockerfile              # MailHog custom image
└── README.md                   # This documentation
```

## Components

### Jenkins CI/CD Platform

#### jenkins-deployment.yaml
Jenkins deployment configuration with the following features:

- **Image**: Custom Jenkins image with plugins
- **Port**: 8080 (HTTP)
- **Storage**: Persistent volume for Jenkins home
- **Resources**: CPU and memory limits
- **Health Checks**: Readiness and liveness probes
- **Environment Variables**: Jenkins configuration

#### jenkins-service.yaml
Service configuration for Jenkins access:

- **Type**: LoadBalancer
- **Port**: 8080
- **Target Port**: 8080
- **External Access**: Available on cluster IP
- **Session Affinity**: None

#### jenkins-pvc.yaml
Persistent volume claim for Jenkins data:

- **Storage Class**: Standard
- **Access Mode**: ReadWriteOnce
- **Size**: 10Gi
- **Purpose**: Jenkins home directory persistence

#### jenkins-rbac.yaml
Role-based access control for Jenkins:

- **Service Account**: jenkins-admin
- **Cluster Role**: Full cluster permissions
- **Role Binding**: Binds service account to cluster role
- **Namespace**: devops-pets

### PostgreSQL Database

#### postgres-deployment.yaml
PostgreSQL deployment configuration:

- **Image**: postgres:15
- **Port**: 5432
- **Storage**: Persistent volume for data
- **Resources**: CPU and memory limits
- **Health Checks**: Readiness and liveness probes
- **Environment Variables**: Database configuration

#### postgres-service.yaml
Service configuration for database access:

- **Type**: ClusterIP
- **Port**: 5432
- **Target Port**: 5432
- **Internal Access**: Available within cluster
- **Session Affinity**: None

#### postgres-pvc.yaml
Persistent volume claim for database data:

- **Storage Class**: Standard
- **Access Mode**: ReadWriteOnce
- **Size**: 5Gi
- **Purpose**: PostgreSQL data directory persistence

#### postgres-secret.yaml
Database credentials and configuration:

- **Database Name**: petdb
- **Username**: petuser
- **Password**: petpass
- **Encoding**: UTF8
- **Locale**: en_US.utf8

### MailHog Email Testing

#### mailhog-deployment.yaml
MailHog deployment configuration:

- **Image**: mailhog/mailhog:latest
- **Port**: 1025 (SMTP), 8025 (HTTP)
- **Storage**: In-memory storage
- **Resources**: CPU and memory limits
- **Health Checks**: Readiness and liveness probes

#### mailhog-service.yaml
Service configuration for MailHog access:

- **Type**: LoadBalancer
- **Ports**: 1025 (SMTP), 8025 (HTTP)
- **Target Ports**: 1025, 8025
- **External Access**: Available on cluster IP
- **Session Affinity**: None

## Configuration Details

### Jenkins Configuration

#### Environment Variables
```yaml
- name: JENKINS_OPTS
  value: "--prefix=/jenkins"
- name: JAVA_OPTS
  value: "-Djenkins.install.runSetupWizard=false"
- name: JENKINS_SLAVE_AGENT_PORT
  value: "50000"
```

#### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /login
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /login
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 5
```

#### Resource Limits
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### PostgreSQL Configuration

#### Environment Variables
```yaml
- name: POSTGRES_DB
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: database
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: username
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: password
```

#### Health Checks
```yaml
livenessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - petuser
    - -d
    - petdb
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - petuser
    - -d
    - petdb
  initialDelaySeconds: 5
  periodSeconds: 5
```

#### Resource Limits
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### MailHog Configuration

#### Environment Variables
```yaml
- name: MH_STORAGE
  value: "memory"
- name: MH_HOSTNAME
  value: "mailhog-service"
```

#### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8025
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /
    port: 8025
  initialDelaySeconds: 5
  periodSeconds: 5
```

#### Resource Limits
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## Deployment Process

### 1. Namespace Creation
```bash
kubectl create namespace devops-pets
kubectl config set-context --current --namespace=devops-pets
```

### 2. Secrets and ConfigMaps
```bash
# Apply database secrets
kubectl apply -f postgres/postgres-secret.yaml

# Apply any additional ConfigMaps
kubectl apply -f configmaps/
```

### 3. Persistent Volumes
```bash
# Apply PVCs
kubectl apply -f jenkins/jenkins-pvc.yaml
kubectl apply -f postgres/postgres-pvc.yaml
```

### 4. RBAC Configuration
```bash
# Apply Jenkins RBAC
kubectl apply -f jenkins/jenkins-rbac.yaml
```

### 5. Application Deployment
```bash
# Deploy PostgreSQL
kubectl apply -f postgres/

# Deploy MailHog
kubectl apply -f mailhog/

# Deploy Jenkins
kubectl apply -f jenkins/
```

### 6. Verification
```bash
# Check pod status
kubectl get pods -n devops-pets

# Check services
kubectl get services -n devops-pets

# Check persistent volumes
kubectl get pv,pvc -n devops-pets
```

## Access Points

### External Access
- **Jenkins**: http://localhost:8082
- **MailHog**: http://localhost:8025
- **Frontend**: Port will be shown in Jenkins pipeline output
- **Backend API**: Port will be shown in Jenkins pipeline output

### Internal Services
- **PostgreSQL**: postgres-service:5432
- **MailHog SMTP**: mailhog-service:1025
- **Jenkins**: jenkins-service:8080

## Storage Configuration

### Persistent Volumes
- **Jenkins Home**: 10Gi for Jenkins data and plugins
- **PostgreSQL Data**: 5Gi for database files
- **Storage Class**: Standard (hostPath for Kind)

### Volume Mounts
```yaml
# Jenkins
- name: jenkins-home
  mountPath: /var/jenkins_home

# PostgreSQL
- name: postgres-data
  mountPath: /var/lib/postgresql/data
```

## Security Configuration

### RBAC (Role-Based Access Control)
- **Jenkins Service Account**: Full cluster permissions
- **Namespace Isolation**: All resources in devops-pets namespace
- **Secret Management**: Database credentials in Kubernetes secrets

### Network Security
- **Service Mesh**: Consider Istio for advanced networking
- **Network Policies**: Restrict pod-to-pod communication
- **Ingress Security**: TLS termination and authentication

## Monitoring and Logging

### Health Checks
- **Readiness Probes**: Ensure services are ready to accept traffic
- **Liveness Probes**: Restart pods if they become unresponsive
- **Startup Probes**: Handle slow-starting containers

### Logging
- **Application Logs**: Container logs via kubectl logs
- **System Logs**: Kubernetes event logs
- **Audit Logs**: API server audit logs

### Metrics
- **Resource Usage**: CPU and memory monitoring
- **Storage Usage**: Persistent volume monitoring
- **Network Traffic**: Service communication metrics

## Troubleshooting

### Common Issues

#### Pod Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n devops-pets

# Check pod logs
kubectl logs <pod-name> -n devops-pets

# Check pod status
kubectl get pods -n devops-pets
```

#### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n devops-pets

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup <service-name>
```

#### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n devops-pets

# Check PV status
kubectl get pv

# Check storage class
kubectl get storageclass
```

### Debugging Commands
```bash
# Port forward to debug
kubectl port-forward <pod-name> <local-port>:<pod-port> -n devops-pets

# Execute commands in pod
kubectl exec -it <pod-name> -n devops-pets -- /bin/sh

# Copy files from/to pod
kubectl cp <pod-name>:/path/to/file ./local-file -n devops-pets
```

## Maintenance

### Updates and Upgrades
- **Rolling Updates**: Zero-downtime deployments
- **Version Management**: Track and update component versions
- **Backup Strategy**: Regular backups of persistent data

### Backup and Recovery
- **Jenkins Data**: Backup Jenkins home directory
- **Database**: Regular PostgreSQL backups
- **Configuration**: Version control for all manifests

### Scaling
- **Horizontal Scaling**: Scale pods based on demand
- **Resource Optimization**: Adjust CPU and memory limits
- **Storage Scaling**: Increase volume sizes as needed

## Performance Optimization

### Resource Management
- **Resource Limits**: Prevent resource exhaustion
- **Resource Requests**: Ensure minimum resources
- **Horizontal Pod Autoscaling**: Automatic scaling based on metrics

### Storage Optimization
- **Storage Class Selection**: Choose appropriate storage class
- **Volume Provisioning**: Optimize volume sizes
- **Data Retention**: Implement data lifecycle policies

### Network Optimization
- **Service Discovery**: Efficient service resolution
- **Load Balancing**: Distribute traffic evenly
- **Connection Pooling**: Optimize database connections 