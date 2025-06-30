# Ansible Automation Scripts

## Overview

This directory contains Ansible playbooks and tasks for automating the complete setup and deployment of the DevPets infrastructure. The automation covers system prerequisites, Kubernetes cluster setup, and application deployment.

## Directory Structure

```
ansible/
├── tasks/                      # Individual task files
│   ├── install-docker.yml      # Docker installation
│   ├── install-kind.yml        # Kind cluster installation
│   ├── install-kubectl.yml     # Kubectl installation
│   ├── install-git.yml         # Git installation
│   ├── install-java.yml        # Java installation
│   ├── install-maven.yml       # Maven installation
│   ├── install-nodejs.yml      # Node.js installation
│   ├── install-python.yml      # Python installation
│   ├── install-docker-compose.yml # Docker Compose installation
│   ├── install-tool.yml        # Generic tool installation
│   ├── create-kind-cluster.yml # Kind cluster creation
│   ├── create-namespace.yml    # Kubernetes namespace creation
│   ├── deploy-jenkins.yml      # Jenkins deployment
│   ├── deploy-postgres.yml     # PostgreSQL deployment
│   ├── deploy-mailhog.yml      # MailHog deployment
│   ├── build-and-load-images.yml # Docker image building
│   ├── apply-base-config.yml   # Base configuration
│   ├── clean-and-rebuild.yml   # Cleanup and rebuild
│   └── prerequisites.yml       # Prerequisites check
├── inventory.ini               # Host inventory configuration
├── ansible.cfg                 # Ansible configuration
├── requirements.yml            # Ansible dependencies
├── deploy-all.yml              # Main deployment playbook
├── install-prerequisites.yml   # Prerequisites installation
├── setup-system.yml            # System setup
├── deploy-applications.yml     # Application deployment
├── validate-deployment.yml     # Deployment validation
├── check-versions.yml          # Version compatibility check
├── run-deployment.sh           # Deployment script
└── stop-deployment.sh          # Stop deployment script
```

## Playbooks

### deploy-all.yml
Main deployment playbook that orchestrates the complete setup:

1. **Prerequisites Check**: Validates system requirements
2. **System Setup**: Installs required tools and dependencies
3. **Cluster Creation**: Sets up Kind Kubernetes cluster
4. **Application Deployment**: Deploys Jenkins, PostgreSQL, and MailHog
5. **Verification**: Validates deployment success

### install-prerequisites.yml
Installs system prerequisites and tools:

- **Docker**: Container runtime
- **Kind**: Kubernetes in Docker
- **Kubectl**: Kubernetes command-line tool
- **Git**: Version control system
- **Java**: OpenJDK 17
- **Maven**: Build tool for Java
- **Node.js**: JavaScript runtime
- **Python**: Python interpreter
- **Docker Compose**: Multi-container orchestration

### setup-system.yml
Sets up the Kubernetes cluster and base configuration:

1. **Kind Cluster**: Creates multi-node Kubernetes cluster
2. **Namespace**: Creates devops-pets namespace
3. **Base Configuration**: Applies base Kubernetes configuration
4. **Load Balancer**: Sets up MetalLB for external access

### deploy-applications.yml
Deploys the core applications:

1. **Jenkins**: CI/CD platform with persistent storage
2. **PostgreSQL**: Database with persistent volume
3. **MailHog**: Email testing service
4. **Ingress Controller**: nginx-ingress for traffic routing

### validate-deployment.yml
Validates the deployment and checks system health:

- **Cluster Status**: Verifies Kind cluster is running
- **Pod Status**: Checks all pods are ready
- **Service Status**: Validates services are accessible
- **Port Availability**: Checks required ports are free

### check-versions.yml
Checks version compatibility and system requirements:

- **Docker Version**: Minimum Docker version check
- **Kubernetes Version**: Kind cluster version validation
- **System Resources**: Memory and disk space verification
- **Network Connectivity**: Internet connectivity test

## Tasks

### System Installation Tasks

#### install-docker.yml
```yaml
- name: Install Docker
  tasks:
  - name: Update package cache
  - name: Install Docker dependencies
  - name: Add Docker GPG key
  - name: Add Docker repository
  - name: Install Docker
  - name: Start and enable Docker service
  - name: Add user to docker group
```

#### install-kind.yml
```yaml
- name: Install Kind
  tasks:
  - name: Download Kind binary
  - name: Make Kind executable
  - name: Verify Kind installation
```

#### install-kubectl.yml
```yaml
- name: Install Kubectl
  tasks:
  - name: Download kubectl binary
  - name: Make kubectl executable
  - name: Verify kubectl installation
```

### Cluster Management Tasks

#### create-kind-cluster.yml
```yaml
- name: Create Kind Cluster
  tasks:
  - name: Delete existing cluster
  - name: Create new cluster
  - name: Wait for cluster to be ready
  - name: Configure kubectl context
```

#### create-namespace.yml
```yaml
- name: Create Namespace
  tasks:
  - name: Create devops-pets namespace
  - name: Set namespace as default
```

### Application Deployment Tasks

#### deploy-jenkins.yml
```yaml
- name: Deploy Jenkins
  tasks:
  - name: Create Jenkins namespace
  - name: Apply Jenkins RBAC
  - name: Deploy Jenkins
  - name: Wait for Jenkins to be ready
  - name: Get Jenkins admin password
```

#### deploy-postgres.yml
```yaml
- name: Deploy PostgreSQL
  tasks:
  - name: Create PostgreSQL secret
  - name: Create PostgreSQL PVC
  - name: Deploy PostgreSQL
  - name: Wait for PostgreSQL to be ready
  - name: Initialize database
```

#### deploy-mailhog.yml
```yaml
- name: Deploy MailHog
  tasks:
  - name: Deploy MailHog
  - name: Wait for MailHog to be ready
  - name: Verify MailHog service
```

## Configuration Files

### inventory.ini
Host inventory configuration:
```ini
[local]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

### ansible.cfg
Ansible configuration:
```ini
[defaults]
host_key_checking = False
inventory = inventory.ini
remote_user = root
timeout = 30
gathering = smart
fact_caching = memory
```

### requirements.yml
Ansible dependencies:
```yaml
---
collections:
  - name: kubernetes.core
    version: ">=2.0.0"
  - name: community.docker
    version: ">=3.0.0"
```

## Deployment Scripts

### run-deployment.sh
Main deployment script with user-friendly interface:

```bash
#!/bin/bash
# Main deployment script with validation and error handling

# Functions
validate_prerequisites() {
    # Check system requirements
}

setup_environment() {
    # Set up Ansible environment
}

run_deployment() {
    # Execute Ansible playbooks
}

main() {
    validate_prerequisites
    setup_environment
    run_deployment
}
```

### stop-deployment.sh
Cleanup and stop deployment script:

```bash
#!/bin/bash
# Stop and cleanup deployment

cleanup_cluster() {
    kind delete cluster --name devops-pets
}

cleanup_ports() {
    pkill -f 'kubectl port-forward'
}

main() {
    cleanup_ports
    cleanup_cluster
}
```

## Usage

### Quick Deployment
```bash
# Run complete deployment
./run-deployment.sh
```

### Step-by-Step Deployment
```bash
# Install prerequisites only
ansible-playbook -i inventory.ini install-prerequisites.yml

# Setup system
ansible-playbook -i inventory.ini setup-system.yml

# Deploy applications
ansible-playbook -i inventory.ini deploy-applications.yml
```

### Validation
```bash
# Validate deployment
ansible-playbook -i inventory.ini validate-deployment.yml

# Check versions
ansible-playbook -i inventory.ini check-versions.yml
```

## Variables

### System Variables
```yaml
# Docker configuration
docker_version: "20.10"
docker_compose_version: "2.0.0"

# Kubernetes configuration
kind_version: "0.20.0"
kubectl_version: "1.28.0"

# Application versions
jenkins_version: "2.414"
postgres_version: "15"
mailhog_version: "1.0.1"
```

### Network Configuration
```yaml
# Port mappings
jenkins_port: 8080
mailhog_port: 8025
postgres_port: 5432

# Cluster configuration
cluster_name: "devops-pets"
namespace: "devops-pets"
```

## Error Handling

### Common Issues
1. **Docker Not Running**: Check Docker service status
2. **Port Conflicts**: Verify ports are available
3. **Permission Issues**: Ensure proper user permissions
4. **Network Issues**: Check internet connectivity

### Debugging
```bash
# Enable verbose output
ansible-playbook -i inventory.ini deploy-all.yml -vvv

# Check specific task
ansible-playbook -i inventory.ini deploy-all.yml --tags "jenkins"

# Dry run
ansible-playbook -i inventory.ini deploy-all.yml --check
```

## Best Practices

### Idempotency
- All tasks are idempotent and can be run multiple times
- Proper state checking before operations
- Conditional execution based on current state

### Error Recovery
- Graceful error handling and cleanup
- Rollback capabilities for failed deployments
- Comprehensive logging and error reporting

### Security
- Minimal required permissions
- Secure credential handling
- Network isolation and security groups

## Maintenance

### Updates
- Regular version updates for tools and applications
- Security patches and vulnerability fixes
- Performance optimizations

### Monitoring
- Deployment status monitoring
- Resource usage tracking
- Error log analysis

### Backup
- Configuration backup
- State preservation
- Disaster recovery procedures 