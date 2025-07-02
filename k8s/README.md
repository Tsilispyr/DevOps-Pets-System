# Kubernetes Υποδομή - Manifests

## Επισκόπηση

Αυτός ο φάκελος περιέχει Kubernetes manifests για την ανάπτυξη των βασικών υποδομών του συστήματος DevPets. Περιλαμβάνει Jenkins CI/CD, PostgreSQL database και MailHog για δοκιμές email.

## Δομή Φακέλου

```
k8s/
├── jenkins/                    # Jenkins CI/CD
│   ├── jenkins-deployment.yaml # Jenkins deployment
│   ├── jenkins-service.yaml    # Jenkins service
│   ├── jenkins-pvc.yaml        # Jenkins persistent volume claim
│   ├── jenkins-rbac.yaml       # Jenkins RBAC
│   └── Dockerfile              # Jenkins custom image
├── postgres/                   # Βάση PostgreSQL
│   ├── postgres-deployment.yaml # PostgreSQL deployment
│   ├── postgres-service.yaml   # PostgreSQL service
│   ├── postgres-pvc.yaml       # PostgreSQL PVC
│   ├── postgres-secret.yaml    # Credentials DB
│   └── Dockerfile              # Custom image
├── mailhog/                    # MailHog για δοκιμές email
│   ├── mailhog-deployment.yaml # MailHog deployment
│   ├── mailhog-service.yaml    # MailHog service
│   └── Dockerfile              # Custom image
└── README.md                   # Τεκμηρίωση
```

## Συνιστώμενα Components

### Jenkins CI/CD

#### jenkins-deployment.yaml
- **Εικόνα**: Custom Jenkins image με plugins
- **Θύρα**: 8080 (HTTP)
- **Αποθήκευση**: Persistent volume για Jenkins home
- **Πόροι**: Όρια CPU/μνήμης
- **Έλεγχοι Υγείας**: Readiness/liveness probes
- **Μεταβλητές Περιβάλλοντος**: Jenkins config

#### jenkins-service.yaml
- **Τύπος**: LoadBalancer
- **Θύρα**: 8080
- **Target Port**: 8080
- **Εξωτερική Πρόσβαση**: Μέσω cluster IP

#### jenkins-pvc.yaml
- **Storage Class**: Standard
- **Access Mode**: ReadWriteOnce
- **Μέγεθος**: 10Gi
- **Σκοπός**: Jenkins home directory

#### jenkins-rbac.yaml
- **Service Account**: jenkins-admin
- **Cluster Role**: Πλήρη δικαιώματα cluster
- **Role Binding**: Σύνδεση με cluster role
- **Namespace**: devops-pets

### PostgreSQL Database

#### postgres-deployment.yaml
- **Εικόνα**: postgres:15
- **Θύρα**: 5432
- **Αποθήκευση**: Persistent volume
- **Πόροι**: Όρια CPU/μνήμης
- **Έλεγχοι Υγείας**: Readiness/liveness probes
- **Μεταβλητές Περιβάλλοντος**: DB config

#### postgres-service.yaml
- **Τύπος**: ClusterIP
- **Θύρα**: 5432
- **Target Port**: 5432
- **Εσωτερική Πρόσβαση**: Μόνο εντός cluster

#### postgres-pvc.yaml
- **Storage Class**: Standard
- **Access Mode**: ReadWriteOnce
- **Μέγεθος**: 5Gi
- **Σκοπός**: Αποθήκευση δεδομένων DB

#### postgres-secret.yaml
- **Database Name**: petdb
- **Username**: petuser
- **Password**: petpass
- **Encoding**: UTF8
- **Locale**: en_US.utf8

### MailHog Email Testing

#### mailhog-deployment.yaml
- **Εικόνα**: mailhog/mailhog:latest
- **Θύρες**: 1025 (SMTP), 8025 (HTTP)
- **Αποθήκευση**: In-memory
- **Πόροι**: Όρια CPU/μνήμης
- **Έλεγχοι Υγείας**: Readiness/liveness probes

#### mailhog-service.yaml
- **Τύπος**: LoadBalancer
- **Θύρες**: 1025 (SMTP), 8025 (HTTP)
- **Target Ports**: 1025, 8025
- **Εξωτερική Πρόσβαση**: Μέσω cluster IP

## Διαδικασία Ανάπτυξης

### 1. Δημιουργία Namespace
```bash
kubectl create namespace devops-pets
kubectl config set-context --current --namespace=devops-pets
```

### 2. Secrets & ConfigMaps
```bash
# Εφαρμογή DB secrets
kubectl apply -f postgres/postgres-secret.yaml

# Εφαρμογή επιπλέον ConfigMaps (αν υπάρχουν)
kubectl apply -f configmaps/
```

### 3. Persistent Volumes
```bash
# Εφαρμογή PVCs
kubectl apply -f jenkins/jenkins-pvc.yaml
kubectl apply -f postgres/postgres-pvc.yaml
```

### 4. RBAC
```bash
# Εφαρμογή Jenkins RBAC
kubectl apply -f jenkins/jenkins-rbac.yaml
```

### 5. Ανάπτυξη Εφαρμογών
```bash
# Deploy PostgreSQL
kubectl apply -f postgres/

# Deploy MailHog
kubectl apply -f mailhog/

# Deploy Jenkins
kubectl apply -f jenkins/
```

### 6. Επαλήθευση
```bash
# Έλεγχος pods
kubectl get pods -n devops-pets

# Έλεγχος services
kubectl get services -n devops-pets

# Έλεγχος persistent volumes
kubectl get pv,pvc -n devops-pets
```

## Σημεία Πρόσβασης

### Εξωτερική Πρόσβαση
- **Jenkins**: https://pet-system-devpets.swedencentral.cloudapp.azure.com
- **MailHog**: http://localhost:8025
- **Frontend**: Εμφανίζεται στο output του pipeline Jenkins
- **Backend API**: Εμφανίζεται στο output του pipeline Jenkins

### Εσωτερικές Υπηρεσίες
- **PostgreSQL**: postgres-service:5432
- **MailHog SMTP**: mailhog-service:1025
- **Jenkins**: jenkins-service:8080

## Ρυθμίσεις Αποθήκευσης

### Persistent Volumes
- **Jenkins Home**: 10Gi για δεδομένα Jenkins
- **PostgreSQL Data**: 5Gi για DB
- **Storage Class**: Standard (hostPath για Kind)

### Volume Mounts
```yaml
# Jenkins
- name: jenkins-home
  mountPath: /var/jenkins_home

# PostgreSQL
- name: postgres-data
  mountPath: /var/lib/postgresql/data
```

## Ασφάλεια

### RBAC
- **Jenkins Service Account**: Πλήρη δικαιώματα
- **Namespace Isolation**: Όλα στο devops-pets
- **Secret Management**: DB credentials σε Kubernetes secrets

### Δικτυακή Ασφάλεια
- **Service Mesh**: (προαιρετικό) Istio
- **Network Policies**: Περιορισμός επικοινωνίας pods
- **Ingress Security**: TLS termination & authentication

## Παρακολούθηση & Logging

### Health Checks
- **Readiness Probes**: Έλεγχος διαθεσιμότητας
- **Liveness Probes**: Αυτόματη επανεκκίνηση pods
- **Startup Probes**: Για αργή εκκίνηση

### Logging
- **Application Logs**: `kubectl logs`
- **System Logs**: Kubernetes events
- **Audit Logs**: API server audit logs

### Metrics
- **Resource Usage**: Παρακολούθηση CPU/μνήμης
- **Storage Usage**: Παρακολούθηση PV
- **Network Traffic**: Παρακολούθηση επικοινωνίας

## Επίλυση Προβλημάτων

### Συχνά Προβλήματα

#### Pod δεν ξεκινά
```bash
kubectl describe pod <pod-name> -n devops-pets
kubectl logs <pod-name> -n devops-pets
kubectl get pods -n devops-pets
```

#### Service μη προσβάσιμο
```bash
kubectl get endpoints -n devops-pets
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup <service-name>
```

#### Προβλήματα αποθήκευσης
```bash
kubectl get pvc -n devops-pets
kubectl get pv
kubectl get storageclass
```

### Debugging
```bash
kubectl port-forward <pod-name> <local-port>:<pod-port> -n devops-pets
kubectl exec -it <pod-name> -n devops-pets -- /bin/sh
kubectl cp <pod-name>:/path/to/file ./local-file -n devops-pets
```

## Συντήρηση

### Ενημερώσεις & Backup
- **Rolling Updates**: Zero-downtime deployments
- **Version Management**: Παρακολούθηση εκδόσεων
- **Backup Strategy**: Τακτικά backup δεδομένων

### Backup & Recovery
- **Jenkins Data**: Backup Jenkins home
- **Database**: Backup PostgreSQL
- **Configuration**: Έλεγχος εκδόσεων manifests

### Scaling
- **Horizontal Scaling**: Αυτόματη κλιμάκωση
- **Resource Optimization**: Ρύθμιση πόρων
- **Storage Scaling**: Αύξηση volumes

## Βελτιστοποίηση Απόδοσης

### Διαχείριση Πόρων
- **Resource Limits**: Αποφυγή εξάντλησης
- **Resource Requests**: Ελάχιστοι πόροι
- **Horizontal Pod Autoscaling**: Αυτόματη κλιμάκωση

### Storage Optimization
- **Storage Class Selection**: Επιλογή storage class
- **Volume Provisioning**: Βελτιστοποίηση μεγέθους
- **Data Retention**: Πολιτικές διατήρησης

### Network Optimization
- **Service Discovery**: Αποδοτική επίλυση
- **Load Balancing**: Ισοκατανομή traffic
- **Connection Pooling**: Βελτιστοποίηση DB connections

---

**Cloud/HTTPS Σημείωση:**
Για παραγωγική χρήση, προτείνεται η χρήση Ingress με HTTPS termination και cert-manager για αυτόματη έκδοση SSL certificates. 