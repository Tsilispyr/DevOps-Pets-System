# Ανάπτυξη Jenkins στο Kubernetes

## Επισκόπηση

Αυτός ο φάκελος περιέχει Kubernetes manifests για την ανάπτυξη του Jenkins CI/CD στην υποδομή DevPets. Το Jenkins παρέχει αυτοματοποιημένες δυνατότητες build και deployment για το σύστημα διαχείρισης υιοθεσιών κατοικιδίων.

## Αρχεία

### jenkins-deployment.yaml
Ρύθμιση deployment Jenkins με τα εξής χαρακτηριστικά:
- **Εικόνα**: Προσαρμοσμένη Jenkins image με προεγκατεστημένα plugins
- **Θύρα**: 8080 (HTTP)
- **Αποθήκευση**: Persistent volume για το Jenkins home directory
- **Πόροι**: Όρια CPU και μνήμης για βέλτιστη απόδοση
- **Έλεγχοι Υγείας**: Readiness και liveness probes
- **Μεταβλητές Περιβάλλοντος**: Jenkins configuration και βελτιστοποίηση

### jenkins-service.yaml
Service τύπου LoadBalancer για εξωτερική πρόσβαση στο Jenkins:
- **Τύπος Service**: LoadBalancer
- **Εξωτερική Θύρα**: 8080
- **Target Port**: 8080
- **Εξωτερική Πρόσβαση**: Μέσω public IP του cluster

### jenkins-pvc.yaml
Persistent volume claim για διατήρηση δεδομένων Jenkins:
- **Storage Class**: Standard
- **Access Mode**: ReadWriteOnce
- **Μέγεθος**: 10Gi
- **Σκοπός**: Jenkins home directory με plugins και job data

### jenkins-rbac.yaml
Ρύθμιση RBAC για το Jenkins:
- **Service Account**: jenkins-admin
- **Cluster Role**: Πλήρη δικαιώματα cluster για CI/CD
- **Role Binding**: Σύνδεση service account με cluster role
- **Namespace**: devops-pets

### Dockerfile
Custom Jenkins image με προεγκατεστημένα plugins και εργαλεία:
- **Βασική Εικόνα**: jenkins/jenkins:lts-jdk17
- **Plugins**: Pipeline, Git, Kubernetes, Docker, Blue Ocean
- **Εργαλεία**: kubectl, docker, git, maven, nodejs

## Ρυθμίσεις Jenkins

### Μεταβλητές Περιβάλλοντος
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

### Έλεγχοι Υγείας
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

### Όρια Πόρων
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

## Διαδικασία Ανάπτυξης

### 1. Προαπαιτούμενα
```bash
# Δημιουργία namespace (αν δεν υπάρχει)
kubectl create namespace devops-pets

# Εφαρμογή RBAC
kubectl apply -f jenkins-rbac.yaml
```

### 2. Ρύθμιση Αποθήκευσης
```bash
# Εφαρμογή PVC
kubectl apply -f jenkins-pvc.yaml

# Έλεγχος PVC
kubectl get pvc -n devops-pets
```

### 3. Ανάπτυξη Jenkins
```bash
# Deploy Jenkins
kubectl apply -f jenkins-deployment.yaml

# Εφαρμογή service
kubectl apply -f jenkins-service.yaml

# Αναμονή για ετοιμότητα deployment
kubectl wait --for=condition=available --timeout=300s deployment/jenkins-deployment -n devops-pets
```

### 4. Επαλήθευση
```bash
# Έλεγχος pods
kubectl get pods -n devops-pets | grep jenkins

# Έλεγχος service
kubectl get services -n devops-pets | grep jenkins

# Λήψη admin password
kubectl exec -it deployment/jenkins-deployment -n devops-pets -- cat /var/jenkins_home/secrets/initialAdminPassword
```

## Πρόσβαση και Ασφάλεια

### Εξωτερική Πρόσβαση
- **URL**: https://pet-system-devpets.swedencentral.cloudapp.azure.com (μέσω Ingress & HTTPS)
- **Authentication**: Username/password
- **SSL**: Ενεργό μέσω cert-manager & Let's Encrypt

### Εσωτερική Πρόσβαση
- **Service Name**: jenkins-service
- **Port**: 8080
- **Namespace**: devops-pets

## HTTPS & Let's Encrypt
- Το Ingress του Jenkins έχει ρυθμιστεί να χρησιμοποιεί το Azure FQDN και ClusterIssuer (cert-manager) για αυτόματη έκδοση SSL certificate μέσω Let's Encrypt.
- Δεν απαιτείται χειροκίνητη διαχείριση πιστοποιητικών.

## Παρακολούθηση & Troubleshooting

### Έλεγχος κατάστασης Jenkins
```bash
kubectl get pods -n devops-pets | grep jenkins
kubectl logs <jenkins-pod-name> -n devops-pets
```

### Έλεγχος certificate
```bash
kubectl describe certificate -n devops-pets
```

### Port-forward για τοπική πρόσβαση (αν χρειαστεί)
```bash
kubectl port-forward service/jenkins-service 8080:8080 -n devops-pets
```

## Συντήρηση & Backup
- Backup του /var/jenkins_home
- Ενημέρωση plugins & Jenkins image

---

**Τελευταία ενημέρωση:** Υποστήριξη HTTPS μέσω Azure FQDN και cert-manager (Let's Encrypt) 