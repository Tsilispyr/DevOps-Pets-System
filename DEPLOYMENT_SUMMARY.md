# DevOps Pets System - Corrected Deployment Process

## Overview
The system has been corrected to use self-signed certificates properly integrated into the deployment process.

## Architecture
- **Dpet**: Infrastructure (Jenkins, Postgres, Mailhog) with self-signed certificates
- **F-B-END**: Application (Frontend, Backend, Minio) with self-signed certificates via Jenkins pipeline

## Corrected Deployment Flow

### 1. Deploy Infrastructure (Dpet)
```bash
cd Dpet
ansible-playbook ansible/deploy-all.yml
```

**What this does:**
-  Creates KIND cluster
-  Deploys ingress-nginx
-  Deploys PostgreSQL
-  **Generates self-signed certificates for Jenkins and Mailhog**
-  **Applies certificates to Kubernetes**
-  Deploys Jenkins with HTTPS
-  Deploys Mailhog with HTTPS
-  **No longer installs cert-manager** (removed)

### 2. Deploy Application (F-B-END)
```bash
# Access Jenkins
https://jenkins.petsystem46.swedencentral.cloudapp.azure.com
# Run the pipeline
```

**What the Jenkinsfile does:**
-  Builds Frontend and Backend
-  **Generates self-signed certificates for Frontend, Backend, Minio**
-  **Applies certificates to Kubernetes**
-  Deploys all application services with HTTPS
-  Applies Ingress configurations

## Key Corrections Made

### Dpet (Infrastructure)
1. **Removed cert-manager installation** from `deploy-all.yml`
2. **Added certificate generation** before Jenkins deployment
3. **Updated Ingress files** to remove cert-manager annotations
4. **Self-signed certificates** for Jenkins and Mailhog

### F-B-END (Application)
1. **Added certificate generation** in Jenkinsfile before Ingress deployment
2. **Updated Ingress files** to remove cert-manager annotations
3. **Self-signed certificates** for Frontend, Backend, Minio
4. **Automatic certificate deployment** during pipeline

## Service URLs (All HTTPS)

### Infrastructure Services
- **Jenkins**: https://jenkins.petsystem46.swedencentral.cloudapp.azure.com
- **Mailhog**: https://mailhog.petsystem46.swedencentral.cloudapp.azure.com

### Application Services
- **Frontend**: https://frontend.petsystem46.swedencentral.cloudapp.azure.com
- **Minio**: https://minio.petsystem46.swedencentral.cloudapp.azure.com
- **API**: https://api.petsystem46.swedencentral.cloudapp.azure.com

## Internal Communication (Unaffected)
- **Backend ↔ Postgres**: `postgres:5432`
- **Backend ↔ Minio**: `minio:9000`
- **Frontend ↔ Backend**: `/api` (via Ingress)

## Browser Warnings
All services use self-signed certificates, so browsers will show security warnings:
1. Click "Advanced" or "Show Details"
2. Click "Proceed to [domain] (unsafe)"
3. Service will load normally

## Troubleshooting

### If Infrastructure Deployment Fails
```bash
cd Dpet
# Check what failed
ansible-playbook ansible/deploy-all.yml --verbose

# Manual certificate generation
chmod +x generate-infrastructure-certs.sh
./generate-infrastructure-certs.sh
kubectl apply -f *-tls-secret.yaml
```

### If Application Deployment Fails
```bash
# Check Jenkins logs
kubectl logs -n devops-pets -l app=jenkins

# Manual certificate generation
cd F-B-END
chmod +x generate-application-certs.sh
./generate-application-certs.sh
kubectl apply -f *-tls-secret.yaml
```

## Advantages of This Approach
-  **No external dependencies** (no cert-manager, no Let's Encrypt)
-  **Immediate availability** (no waiting for certificate issuance)
-  **Demo-friendly** (works immediately for presentations)
-  **Integrated deployment** (certificates are part of the deployment process)
-  **Separate concerns** (infrastructure vs application)
-  **Pipeline integration** (application certificates handled automatically)

## Next Steps
1. Run `ansible-playbook ansible/deploy-all.yml` in Dpet directory
2. Access Jenkins and run the pipeline
3. Test all services via HTTPS 