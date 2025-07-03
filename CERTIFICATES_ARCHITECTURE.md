# Self-Signed Certificates Architecture

This document explains the self-signed certificates setup for the DevOps Pets System with separate repositories.

## Architecture Overview

The system is split into two separate repositories:

### 1. **Dpet Repository** (Infrastructure)
- **Purpose**: Infrastructure services (Jenkins, Postgres, Mailhog)
- **Location**: `Dpet/` directory
- **Services**: Jenkins, Postgres, Mailhog
- **Certificates**: jenkins-tls, mailhog-tls

### 2. **F-B-END Repository** (Application)
- **Purpose**: Application services (Frontend, Backend, Minio)
- **Location**: `F-B-END/` directory  
- **Services**: Frontend, Backend, Minio
- **Certificates**: frontend-tls, minio-tls, pet-system-tls

## Deployment Flow

### Step 1: Deploy Infrastructure (Dpet)
```bash
cd Dpet
chmod +x deploy-self-signed-certs.sh
./deploy-self-signed-certs.sh
```

This will:
- Generate certificates for Jenkins and Mailhog
- Apply certificates to Kubernetes
- Deploy Jenkins and Mailhog with HTTPS

### Step 2: Deploy Application (F-B-END)
The application deployment happens automatically through Jenkins pipeline:

1. **Access Jenkins**: `https://jenkins.petsystem46.swedencentral.cloudapp.azure.com`
2. **Run Pipeline**: The Jenkinsfile automatically:
   - Generates certificates for Frontend, Backend, Minio
   - Applies certificates to Kubernetes
   - Deploys application services with HTTPS

## Certificate Files

### Dpet (Infrastructure)
- `Dpet/generate-infrastructure-certs.sh` - Generates Jenkins and Mailhog certificates
- `Dpet/deploy-self-signed-certs.sh` - Deploys infrastructure certificates
- `Dpet/certs/` - Certificate files directory
- `Dpet/*-tls-secret.yaml` - Kubernetes secret files

### F-B-END (Application)
- `F-B-END/generate-application-certs.sh` - Generates Frontend, Backend, Minio certificates
- `F-B-END/deploy-application-certs.sh` - Deploys application certificates (manual)
- `F-B-END/Jenkinsfile` - Automatically generates and deploys certificates during pipeline
- `F-B-END/certs/` - Certificate files directory
- `F-B-END/*-tls-secret.yaml` - Kubernetes secret files

## Service URLs

### Infrastructure Services (Dpet)
- **Jenkins**: https://jenkins.petsystem46.swedencentral.cloudapp.azure.com
- **Mailhog**: https://mailhog.petsystem46.swedencentral.cloudapp.azure.com

### Application Services (F-B-END)
- **Frontend**: https://frontend.petsystem46.swedencentral.cloudapp.azure.com
- **Minio**: https://minio.petsystem46.swedencentral.cloudapp.azure.com
- **API**: https://api.petsystem46.swedencentral.cloudapp.azure.com

## Manual Application Deployment

If you need to manually deploy application certificates (without Jenkins):

```bash
cd F-B-END
chmod +x deploy-application-certs.sh
./deploy-application-certs.sh
```

## Certificate Renewal

### Infrastructure Certificates (Dpet)
```bash
cd Dpet
./generate-infrastructure-certs.sh
kubectl apply -f *-tls-secret.yaml
```

### Application Certificates (F-B-END)
```bash
cd F-B-END
./generate-application-certs.sh
kubectl apply -f *-tls-secret.yaml
```

Or simply re-run the Jenkins pipeline which will regenerate certificates automatically.

## Troubleshooting

### Certificate Issues
1. Check if secrets exist: `kubectl get secrets -n devops-pets | grep tls`
2. Check ingress status: `kubectl get ingress -n devops-pets`
3. Check certificate validity: `kubectl describe secret <cert-name> -n devops-pets`

### Service Access Issues
1. Verify DNS resolution: `nslookup <domain>`
2. Check if pods are running: `kubectl get pods -n devops-pets`
3. Check ingress events: `kubectl describe ingress <ingress-name> -n devops-pets`

## Browser Warnings

All services use self-signed certificates, so browsers will show security warnings. This is normal:

1. Click "Advanced" or "Show Details"
2. Click "Proceed to [domain] (unsafe)"
3. The service will load normally

## Advantages of This Architecture

- **Separation of Concerns**: Infrastructure and application are separate
- **Independent Deployment**: Can deploy infrastructure without application
- **Pipeline Integration**: Application certificates are handled automatically
- **No External Dependencies**: No need for cert-manager or Let's Encrypt
- **Demo-Friendly**: Works immediately for presentations 