# DevPets Infrastructure Project

## Overview

DevPets-main is the infrastructure and DevOps automation component of the pet adoption management system. It provides a complete Kubernetes-based development environment with Jenkins CI/CD, PostgreSQL database, MailHog email testing, and automated deployment capabilities.

## Project Structure

```
Devpets-main/
├── ansible/                    # Ansible automation scripts
│   ├── tasks/                  # Individual task files
│   ├── inventory.ini           # Host inventory
│   ├── ansible.cfg             # Ansible configuration
│   └── requirements.yml        # Ansible dependencies
├── k8s/                        # Kubernetes manifests
│   ├── jenkins/                # Jenkins deployment
│   ├── postgres/               # PostgreSQL deployment
│   └── mailhog/                # MailHog deployment
├── jenkins_home/               # Jenkins persistent data
├── docker-compose.yml          # Local development setup
├── kind-config.yaml            # Kind cluster configuration
└── README.md                   # This documentation
```

## Components

### Infrastructure Services

#### Kind Kubernetes Cluster
- **Purpose**: Local Kubernetes cluster for development
- **Configuration**: Multi-node cluster with load balancer
- **Storage**: HostPath volumes for persistent data
- **Network**: Custom network configuration

#### Jenkins CI/CD
- **Purpose**: Automated build and deployment pipeline
- **Features**: Pipeline as Code, Blue Ocean interface
- **Storage**: Persistent Jenkins home directory
- **Access**: Web interface on port 8080

#### PostgreSQL Database
- **Purpose**: Primary database for the application
- **Version**: PostgreSQL 15
- **Storage**: Persistent volume for data
- **Access**: Internal service on port 5432

#### MailHog Email Testing
- **Purpose**: Email testing and development
- **Features**: SMTP server, web interface
- **Storage**: In-memory email storage
- **Access**: Web interface on port 8025

### Ansible Automation

#### Playbooks
- **install-prerequisites.yml**: System dependencies and tools
- **setup-system.yml**: Docker, Kind, and Kubernetes setup
- **deploy-applications.yml**: Application deployment
- **deploy-all.yml**: Complete system deployment

#### Tasks
- **Docker Installation**: Container runtime setup
- **Kind Installation**: Kubernetes cluster creation
- **Kubectl Configuration**: Cluster access setup
- **Jenkins Deployment**: CI/CD platform setup
- **Database Setup**: PostgreSQL deployment
- **Email Service**: MailHog deployment

## Prerequisites

- Windows 10/11 with WSL2 enabled
- Docker Desktop installed and running
- Git installed
- At least 8GB RAM available
- Administrator privileges for WSL2

## Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd Devpets-main
```

### 2. Run Deployment
```bash
./deploy
```

### 3. Wait for Completion
The deployment process takes 5-10 minutes and includes:
- System prerequisites installation
- Docker and Kind setup
- Kubernetes cluster creation
- Jenkins deployment
- Database and email services setup

### 4. Access Services
- **Jenkins**: http://localhost:8082
- **MailHog**: http://localhost:8025
- **Frontend**: URL will be shown in Jenkins pipeline output (typically http://localhost:3000 or LoadBalancer IP)
- **Backend API**: URL will be shown in Jenkins pipeline output (typically http://localhost:3000/api or LoadBalancer IP:8080)
- **Kubernetes Dashboard**: Available via kubectl

## Detailed Setup Process

### System Prerequisites
1. **Docker Installation**: Container runtime for Kind
2. **Kind Installation**: Local Kubernetes cluster
3. **Kubectl Installation**: Kubernetes command-line tool
4. **Git Installation**: Version control system

### Kubernetes Cluster Setup
1. **Cluster Creation**: Multi-node Kind cluster
2. **Network Configuration**: Custom networking setup
3. **Storage Configuration**: HostPath volumes
4. **Load Balancer**: MetalLB for external access

### Application Deployment
1. **Jenkins Setup**: CI/CD platform deployment
2. **Database Setup**: PostgreSQL with persistent storage
3. **Email Service**: MailHog for email testing
4. **Ingress Controller**: nginx-ingress for traffic routing

## Configuration

### Kind Cluster Configuration
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
  - containerPort: 443
    hostPort: 443
- role: worker
- role: worker
```

### Jenkins Configuration
- **Namespace**: devops-pets
- **Service Account**: jenkins-admin
- **RBAC**: Full cluster permissions
- **Storage**: Persistent volume for Jenkins home

### Database Configuration
- **Database Name**: petdb
- **Username**: petuser
- **Password**: petpass
- **Port**: 5432
- **Storage**: 1Gi persistent volume

## Access Points

### External Access
- **Jenkins**: http://localhost:8082
- **MailHog**: http://localhost:8025
- **Frontend**: URL will be shown in Jenkins pipeline output (typically http://localhost:3000 or LoadBalancer IP)
- **Backend API**: URL will be shown in Jenkins pipeline output (typically http://localhost:3000/api or LoadBalancer IP:8080)

### Internal Services
- **PostgreSQL**: postgres-service:5432
- **MailHog SMTP**: mailhog-service:1025
- **Kubernetes API**: kubernetes.default.svc

## Development Workflow

### 1. Infrastructure Setup
```bash
cd Devpets-main
./deploy
```

### 2. Application Development
```bash
cd ../F-B-END
# Develop frontend and backend applications
```

### 3. CI/CD Pipeline
- Access Jenkins at http://localhost:8082
- Create pipeline job for F-B-END repository
- Run automated build and deployment

### 4. Testing and Validation
- Test application at URL shown in Jenkins pipeline output (typically http://localhost)
- Check email functionality via MailHog at http://localhost:8025
- Monitor logs and metrics

## Troubleshooting

### Common Issues

#### Kind Cluster Not Starting
```bash
# Check Docker status
docker info

# Restart Docker Desktop
# Recreate Kind cluster
kind delete cluster --name devops-pets
kind create cluster --config kind-config.yaml
```

#### Jenkins Not Accessible
```bash
# Check Jenkins pod status
kubectl get pods -n devops-pets

# Check Jenkins logs
kubectl logs -n devops-pets deployment/jenkins-deployment

# Port forward if needed
kubectl port-forward -n devops-pets service/jenkins-service 8080:8080
```

#### Database Connection Issues
```bash
# Check PostgreSQL pod
kubectl get pods -n devops-pets | grep postgres

# Check database logs
kubectl logs -n devops-pets deployment/postgres-deployment

# Test database connection
kubectl exec -it -n devops-pets deployment/postgres-deployment -- psql -U petuser -d petdb
```

### Useful Commands
```bash
# Check cluster status
kubectl cluster-info

# List all resources
kubectl get all -n devops-pets

# Check services
kubectl get services -n devops-pets

# Check persistent volumes
kubectl get pv,pvc -n devops-pets

# View logs
kubectl logs -n devops-pets <pod-name>

# Execute commands in pods
kubectl exec -it -n devops-pets <pod-name> -- /bin/sh
```

## Maintenance

### Backup and Recovery
- **Jenkins Data**: Backup jenkins_home directory
- **Database**: Regular PostgreSQL backups
- **Configuration**: Version control for all manifests
- **Cluster State**: Export and backup cluster configuration

### Updates and Upgrades
- **Kind Cluster**: Recreate with new configuration
- **Jenkins**: Update Jenkins version and plugins
- **Database**: PostgreSQL version upgrades
- **Applications**: Rolling updates via Jenkins pipeline

### Monitoring
- **Resource Usage**: Monitor CPU and memory usage
- **Storage**: Track persistent volume usage
- **Logs**: Centralized logging and monitoring
- **Health Checks**: Application and service health monitoring

## Security Considerations

### Network Security
- **Namespace Isolation**: Separate namespaces for different components
- **Service Mesh**: Consider Istio for advanced networking
- **Network Policies**: Restrict pod-to-pod communication

### Access Control
- **RBAC**: Role-based access control for Kubernetes
- **Service Accounts**: Limited permissions for pods
- **Secrets Management**: Secure storage for sensitive data

### Data Protection
- **Encryption**: Encrypt data at rest and in transit
- **Backup**: Regular backup of critical data
- **Audit Logging**: Track access and changes

## Performance Optimization

### Resource Management
- **Resource Limits**: Set appropriate CPU and memory limits
- **Horizontal Scaling**: Scale applications based on demand
- **Storage Optimization**: Use appropriate storage classes

### Network Optimization
- **Load Balancing**: Efficient traffic distribution
- **Caching**: Implement caching strategies
- **CDN**: Use CDN for static assets

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes and test locally
4. Submit pull request with detailed description
5. Ensure all tests pass
6. Update documentation as needed

## License

This project is licensed under the MIT License.

## Access URLs

- **Frontend:** http://localhost:8081
- **Backend API:** http://localhost:8080/api
- **Jenkins:** http://localhost:8082
- **MailHog:** http://localhost:8025

## Port Forwarding

Port forwarding for frontend (8081:80) and backend (8080:8080) is handled automatically by the Ansible playbook (`deploy-all.yml`).

## Useful Commands
- Check status: kubectl get all -n devops-pets
- View logs: kubectl logs -n devops-pets <pod-name>
- Stop forwarding: pkill -f 'kubectl port-forward'

## Notes
- The backend always listens on port 8080.
- The frontend is exposed on port 8081 via port-forward.



 
