#!/bin/bash

echo "=== Dpet Infrastructure Self-Signed Certificates Deployment ==="
echo "This script will generate self-signed certificates for infrastructure services"
echo ""

# Check if we're in the right directory
if [ ! -f "generate-infrastructure-certs.sh" ]; then
    echo "Error: Please run this script from the Dpet directory"
    exit 1
fi

# Make the script executable and run it
chmod +x generate-infrastructure-certs.sh
./generate-infrastructure-certs.sh

echo ""
echo "=== Applying infrastructure certificates to Kubernetes ==="

# Apply the certificate secrets for infrastructure only
kubectl apply -f jenkins-tls-secret.yaml
kubectl apply -f mailhog-tls-secret.yaml

echo ""
echo "=== Updating Infrastructure Ingress resources ==="

# Apply the updated ingress configurations for infrastructure only
echo "Applying Jenkins ingress..."
kubectl apply -f k8s/jenkins/jenkins-ingress.yaml

echo "Applying Mailhog ingress..."
kubectl apply -f k8s/mailhog/mailhog-ingress.yaml

echo ""
echo "=== Verification ==="
echo "Checking infrastructure certificate secrets..."
kubectl get secrets -n devops-pets | grep tls

echo ""
echo "Checking infrastructure ingress status..."
kubectl get ingress -n devops-pets

echo ""
echo "=== Infrastructure Services Available ==="
echo "1. Wait a few minutes for the ingress to update"
echo "2. Test access to infrastructure services:"
echo "   - Jenkins: https://jenkins.petsystem46.swedencentral.cloudapp.azure.com"
echo "   - Mailhog: https://mailhog.petsystem46.swedencentral.cloudapp.azure.com"
echo ""
echo "Note: You'll see a browser warning about self-signed certificates."
echo "This is normal - click 'Advanced' and 'Proceed' to access the services."
echo ""
echo "=== Next Steps ==="
echo "1. Access Jenkins and run the pipeline"
echo "2. The pipeline will deploy Frontend, Backend, and Minio with their own certificates" 