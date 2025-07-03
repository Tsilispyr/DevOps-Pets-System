# Self-Signed Certificates Setup

This guide explains how to use self-signed certificates instead of Let's Encrypt for the DevOps Pets System.

## Overview

The system has been updated to use self-signed certificates for all HTTPS endpoints:
- Jenkins: `jenkins.petsystem46.swedencentral.cloudapp.azure.com`
- Frontend: `frontend.petsystem46.swedencentral.cloudapp.azure.com`
- Minio: `minio.petsystem46.swedencentral.cloudapp.azure.com`
- Mailhog: `mailhog.petsystem46.swedencentral.cloudapp.azure.com`

## Changes Made

### 1. Updated Ingress Files
The following files have been modified to remove cert-manager dependencies:
- `Dpet/k8s/jenkins/jenkins-ingress.yaml`
- `F-B-END/k8s/minio/minio-ingress.yaml`
- `F-B-END/ingress.yaml`
- `Dpet/k8s/mailhog/mailhog-ingress.yaml`

### 2. Certificate Generation Script
- `generate-self-signed-certs.sh` - Generates certificates and creates Kubernetes secrets

### 3. Deployment Script
- `deploy-self-signed-certs.sh` - Complete deployment process

## Quick Deployment

### Option 1: Automated Deployment
```bash
chmod +x deploy-self-signed-certs.sh
./deploy-self-signed-certs.sh
```

### Option 2: Manual Steps
```bash
# 1. Generate certificates
chmod +x generate-self-signed-certs.sh
./generate-self-signed-certs.sh

# 2. Apply secrets
kubectl apply -f jenkins-tls-secret.yaml
kubectl apply -f frontend-tls-secret.yaml
kubectl apply -f minio-tls-secret.yaml
kubectl apply -f pet-system-tls-secret.yaml
kubectl apply -f mailhog-tls-secret.yaml

# 3. Apply updated ingress configurations
kubectl apply -f Dpet/k8s/jenkins/jenkins-ingress.yaml
kubectl apply -f F-B-END/k8s/minio/minio-ingress.yaml
kubectl apply -f F-B-END/ingress.yaml
kubectl apply -f Dpet/k8s/mailhog/mailhog-ingress.yaml
```

## Verification

Check that certificates are applied:
```bash
kubectl get secrets -n devops-pets | grep tls
```

Check ingress status:
```bash
kubectl get ingress -n devops-pets
```

## Accessing Services

After deployment, you can access the services at:
- **Jenkins**: https://jenkins.petsystem46.swedencentral.cloudapp.azure.com
- **Frontend**: https://frontend.petsystem46.swedencentral.cloudapp.azure.com
- **Minio**: https://minio.petsystem46.swedencentral.cloudapp.azure.com
- **Mailhog**: https://mailhog.petsystem46.swedencentral.cloudapp.azure.com

## Browser Warnings

When accessing the services, you'll see a browser warning about the self-signed certificate. This is normal and expected. To proceed:

1. Click "Advanced" or "Show Details"
2. Click "Proceed to [domain] (unsafe)" or similar option
3. The service will load normally

## Testing with curl

Test connectivity with curl (ignore certificate warnings):
```bash
curl -vk https://jenkins.petsystem46.swedencentral.cloudapp.azure.com
curl -vk https://frontend.petsystem46.swedencentral.cloudapp.azure.com
curl -vk https://minio.petsystem46.swedencentral.cloudapp.azure.com
```

## Troubleshooting

### Certificate not working
1. Check if secrets exist: `kubectl get secrets -n devops-pets`
2. Check ingress status: `kubectl get ingress -n devops-pets`
3. Check ingress events: `kubectl describe ingress -n devops-pets`

### Service not accessible
1. Verify DNS resolution: `nslookup [domain]`
2. Check if pods are running: `kubectl get pods -n devops-pets`
3. Check service status: `kubectl get svc -n devops-pets`

## Advantages of Self-Signed Certificates

- **No external dependencies**: No need for cert-manager or Let's Encrypt
- **Immediate availability**: No waiting for certificate issuance
- **Demo-friendly**: Works immediately for presentations
- **No rate limits**: No Let's Encrypt rate limiting concerns

## Disadvantages

- **Browser warnings**: Users see security warnings
- **Not trusted**: Certificates are not trusted by browsers
- **Manual renewal**: Certificates expire after 1 year and need manual renewal

## Certificate Renewal

Certificates are valid for 1 year. To renew:
1. Run the generation script again
2. Apply the new secrets
3. Restart the ingress controller if needed

```bash
./generate-self-signed-certs.sh
kubectl apply -f *-tls-secret.yaml
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx
``` 