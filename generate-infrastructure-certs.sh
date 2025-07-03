#!/bin/bash

# Generate self-signed certificates for Dpet infrastructure services
echo "Generating self-signed certificates for Dpet infrastructure..."

# Create certificates directory
mkdir -p certs

# Generate certificates for infrastructure services only
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/jenkins-tls.key -out certs/jenkins-tls.crt \
  -subj "/CN=jenkins.petsystem46.swedencentral.cloudapp.azure.com"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/mailhog-tls.key -out certs/mailhog-tls.crt \
  -subj "/CN=mailhog.petsystem46.swedencentral.cloudapp.azure.com"

echo "Infrastructure certificates generated successfully!"
echo "Now creating Kubernetes secrets..."

# Create Kubernetes secrets for infrastructure
kubectl create secret tls jenkins-tls \
  --key certs/jenkins-tls.key --cert certs/jenkins-tls.crt \
  -n devops-pets --dry-run=client -o yaml > jenkins-tls-secret.yaml

kubectl create secret tls mailhog-tls \
  --key certs/mailhog-tls.key --cert certs/mailhog-tls.crt \
  -n devops-pets --dry-run=client -o yaml > mailhog-tls-secret.yaml

echo "Infrastructure secret YAML files created!"
echo "Apply them with: kubectl apply -f *-tls-secret.yaml" 