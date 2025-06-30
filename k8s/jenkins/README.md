# Jenkins Kubernetes Deployment

## Overview

This directory contains Kubernetes manifests for deploying Jenkins CI/CD platform in the DevPets infrastructure. Jenkins provides automated build and deployment capabilities for the pet adoption management system.

## Files

### jenkins-deployment.yaml
Jenkins deployment configuration with the following features:

- **Image**: Custom Jenkins image with pre-installed plugins
- **Port**: 8080 (HTTP)
- **Storage**: Persistent volume for Jenkins home directory
- **Resources**: CPU and memory limits for optimal performance
- **Health Checks**: Readiness and liveness probes
- **Environment Variables**: Jenkins configuration and optimization

### jenkins-service.yaml
LoadBalancer service configuration for external Jenkins access:

- **Service Type**: LoadBalancer
- **External Port**: 8080
- **Target Port**: 8080
- **External Access**: Available via cluster IP
- **Session Affinity**: None (stateless)

### jenkins-pvc.yaml
Persistent volume claim for Jenkins data persistence:

- **Storage Class**: Standard
- **Access Mode**: ReadWriteOnce
- **Size**: 10Gi
- **Purpose**: Jenkins home directory with plugins and job data

### jenkins-rbac.yaml
Role-based access control configuration for Jenkins:

- **Service Account**: jenkins-admin
- **Cluster Role**: Full cluster permissions for CI/CD operations
- **Role Binding**: Binds service account to cluster role
- **Namespace**: devops-pets

### Dockerfile
Custom Jenkins image with pre-installed plugins and tools:

- **Base Image**: jenkins/jenkins:lts-jdk17
- **Plugins**: Pipeline, Git, Kubernetes, Docker, Blue Ocean
- **Tools**: kubectl, docker, git, maven, nodejs
- **Configuration**: Optimized for containerized environment

## Configuration Details

### Jenkins Environment Variables
```yaml
- name: JENKINS_OPTS
  value: "--prefix=/jenkins"
- name: JAVA_OPTS
  value: "-Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.installState=INITIAL_SETUP_COMPLETED"
- name: JENKINS_SLAVE_AGENT_PORT
  value: "50000"
- name: JENKINS_UC
  value: "https://updates.jenkins.io"
- name: JENKINS_UC_DOWNLOAD
  value: "https://updates.jenkins.io/download"
```

### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /login
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
readinessProbe:
  httpGet:
    path: /login
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

### Resource Limits
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### Volume Mounts
```yaml
volumeMounts:
- name: jenkins-home
  mountPath: /var/jenkins_home
- name: jenkins-config
  mountPath: /var/jenkins_home/init.groovy.d
```

## Deployment Process

### 1. Prerequisites
```bash
# Create namespace (if not exists)
kubectl create namespace devops-pets

# Apply RBAC configuration
kubectl apply -f jenkins-rbac.yaml
```

### 2. Storage Setup
```bash
# Apply persistent volume claim
kubectl apply -f jenkins-pvc.yaml

# Verify PVC status
kubectl get pvc -n devops-pets
```

### 3. Jenkins Deployment
```bash
# Deploy Jenkins
kubectl apply -f jenkins-deployment.yaml

# Apply service
kubectl apply -f jenkins-service.yaml

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/jenkins-deployment -n devops-pets
```

### 4. Verification
```bash
# Check pod status
kubectl get pods -n devops-pets | grep jenkins

# Check service
kubectl get services -n devops-pets | grep jenkins

# Get Jenkins admin password
kubectl exec -it deployment/jenkins-deployment -n devops-pets -- cat /var/jenkins_home/secrets/initialAdminPassword
```

## Jenkins Configuration

### Pre-installed Plugins
The custom Jenkins image includes the following plugins:

- **Pipeline**: Pipeline as Code support
- **Git**: Git integration for source code management
- **Kubernetes**: Kubernetes plugin for dynamic agents
- **Docker**: Docker integration for containerized builds
- **Blue Ocean**: Modern Jenkins UI
- **Credentials**: Secure credential management
- **SSH**: SSH agent support
- **Maven**: Maven integration
- **NodeJS**: Node.js support

### Initial Setup
Jenkins is configured to skip the initial setup wizard and use pre-configured settings:

- **Admin User**: admin
- **Initial Password**: Generated automatically
- **Plugin Installation**: Pre-installed essential plugins
- **Security**: Basic security configuration

### Pipeline Configuration
Jenkins is configured to support:

- **Pipeline as Code**: Jenkinsfile support
- **Multi-branch Pipelines**: Automatic branch detection
- **GitHub Integration**: Webhook support
- **Kubernetes Agents**: Dynamic pod creation for builds

## Access and Security

### External Access
- **URL**: http://localhost:8082
- **Authentication**: Username/password
- **SSL**: Not configured (development environment)

### Internal Access
- **Service Name**: jenkins-service
- **Port**: 8080
- **Namespace**: devops-pets

### Application Access
- **Frontend**: Port will be shown in Jenkins pipeline output
- **Backend API**: Port will be shown in Jenkins pipeline output

### Security Configuration
- **RBAC**: Full cluster permissions for CI/CD operations
- **Service Account**: jenkins-admin with cluster-admin role
- **Network Policy**: No restrictions (development environment)
- **Secrets**: Kubernetes secrets for sensitive data

## Monitoring and Logging

### Health Monitoring
- **Readiness Probe**: Ensures Jenkins is ready to accept requests
- **Liveness Probe**: Restarts Jenkins if it becomes unresponsive
- **Startup Probe**: Handles slow startup scenarios

### Logging
- **Application Logs**: Jenkins application logs
- **System Logs**: Container and Kubernetes logs
- **Build Logs**: Pipeline and job execution logs

### Metrics
- **Resource Usage**: CPU and memory monitoring
- **Build Metrics**: Job success/failure rates
- **Performance**: Response time and throughput

## Troubleshooting

### Common Issues

#### Jenkins Not Starting
```bash
# Check pod events
kubectl describe pod <jenkins-pod-name> -n devops-pets

# Check Jenkins logs
kubectl logs <jenkins-pod-name> -n devops-pets

# Check resource usage
kubectl top pod <jenkins-pod-name> -n devops-pets
```

#### Storage Issues
```bash
# Check PVC status
kubectl get pvc jenkins-pvc -n devops-pets

# Check PV status
kubectl get pv

# Check storage class
kubectl get storageclass
```

#### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints jenkins-service -n devops-pets

# Port forward for debugging
kubectl port-forward service/jenkins-service 8080:8080 -n devops-pets
```

### Debugging Commands
```bash
# Execute shell in Jenkins pod
kubectl exec -it <jenkins-pod-name> -n devops-pets -- /bin/bash

# Check Jenkins home directory
kubectl exec -it <jenkins-pod-name> -n devops-pets -- ls -la /var/jenkins_home

# Check Jenkins configuration
kubectl exec -it <jenkins-pod-name> -n devops-pets -- cat /var/jenkins_home/config.xml
```

## Maintenance

### Updates and Upgrades
- **Image Updates**: Update Jenkins base image and plugins
- **Configuration Changes**: Modify Jenkins configuration
- **Plugin Updates**: Update installed plugins

### Backup and Recovery
- **Jenkins Home**: Backup /var/jenkins_home directory
- **Configuration**: Export Jenkins configuration
- **Jobs**: Backup job definitions and build history

### Scaling
- **Horizontal Scaling**: Scale Jenkins replicas (not recommended)
- **Resource Scaling**: Adjust CPU and memory limits
- **Storage Scaling**: Increase PVC size if needed

## Performance Optimization

### Resource Optimization
- **Memory**: Optimize JVM heap size
- **CPU**: Adjust CPU limits based on workload
- **Storage**: Use appropriate storage class

### Build Optimization
- **Parallel Builds**: Configure concurrent build limits
- **Build Agents**: Use Kubernetes agents for scalability
- **Caching**: Implement build cache strategies

### Network Optimization
- **Service Discovery**: Efficient service resolution
- **Load Balancing**: Distribute traffic evenly
- **Connection Pooling**: Optimize external connections

## Integration

### Kubernetes Integration
- **Dynamic Agents**: Kubernetes pods as build agents
- **Service Discovery**: Access to cluster services
- **Resource Management**: Kubernetes resource limits

### External Integrations
- **Git Repositories**: GitHub, GitLab, Bitbucket
- **Docker Registry**: Container image registry
- **Notification Systems**: Email, Slack, Teams

### CI/CD Pipeline Integration
- **Pipeline as Code**: Jenkinsfile support
- **Multi-branch Pipelines**: Automatic branch handling
- **Webhook Support**: Automatic trigger on code changes 