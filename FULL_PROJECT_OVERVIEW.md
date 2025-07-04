# DevPets - Πλήρης Περιγραφή Υποδομής & Διαδικασιών

## Παραδοχές
- Το σύστημα αναπτύσσεται σε Azure VM με Azure Load Balancer και static public IP.
- Όλα τα endpoints (frontend, backend, Jenkins) εξυπηρετούνται μέσω ingress-nginx με HTTPS termination (Let's Encrypt/cert-manager).
- Η επικοινωνία μεταξύ μικροϋπηρεσιών γίνεται μέσω internal Kubernetes services.
- Η υποδομή (Jenkins, Postgres, Mailhog, MinIO) διαχειρίζεται από το directory `Dpet`, ενώ το application layer (frontend, backend) από το `F-B-END`.
- Όλα τα secrets διαχειρίζονται ως Kubernetes secrets ή .env αρχεία (όχι σκληροκωδικοί στον κώδικα).
- Η υποδομή είναι cloud-ready (Azure), αλλά μπορεί να τρέξει και τοπικά (kind/minikube).

## Deployment
- **Azure VM** (Ubuntu): Kubernetes node, εγκατεστημένα Docker, kubectl, Helm, Ansible, Jenkins.
- **Azure Load Balancer**: Συνδεδεμένο με static public IP (135.225.93.72), προωθεί traffic στις θύρες 80/443 προς το cluster.
- **Public IP**: Συνδεδεμένο μόνο με το Load Balancer.
- **Network Security Groups (NSG)**: Επιτρέπουν traffic στις θύρες 22 (SSH), 80, 443.
- **Kubernetes Cluster**: Όλα τα resources σε namespace `devops-pets`.

## Ansible
- Εγκατάσταση Docker, kubectl, Helm, Java, Node.js, Maven, Git.
- Εγκατάσταση και ρύθμιση Jenkins (container ή systemd service).
- Εγκατάσταση Kubernetes cluster (kind ή kubeadm).
- Deploy βασικών υποδομών (Jenkins, Postgres, Mailhog, MinIO) μέσω Ansible tasks που εφαρμόζουν τα αντίστοιχα Kubernetes manifests.
- Αυτοματισμοί για επαναλαμβανόμενη εγκατάσταση dependencies και deploy/upgrade core services.

## Ansible - Docker
- Εγκατάσταση Docker engine στη VM μέσω Ansible.
- Εκκίνηση Jenkins ως Docker container (αν δεν τρέχει ως pod).
- Εκκίνηση Mailhog, MinIO, Postgres ως containers για local dev/testing (προαιρετικά).
- Docker Compose για local ανάπτυξη όλων των υπηρεσιών εκτός Kubernetes.

## Kubernetes
### Οντότητες που δημιουργήθηκαν:
- **Namespaces**: `devops-pets` (project), `ingress-nginx` (ingress controller)
- **Deployments**:
  - Jenkins: Custom image, persistent storage, RBAC, service account
  - PostgreSQL: StatefulSet/Deployment, PVC, secret για credentials
  - Mailhog: Deployment, service για SMTP/HTTP
  - MinIO: Deployment, PVC, service
  - Backend: Spring Boot JAR, deployment, service, config με env vars
  - Frontend: Vue.js build, deployment (nginx), service, configMap για nginx.conf
- **Services**:
  - ClusterIP για internal επικοινωνία (Postgres, Mailhog, MinIO)
  - LoadBalancer για frontend, backend, Jenkins (μέσω ingress)
  - NodePort (μόνο για debugging/port-forward)
- **Ingress**:
  - Ένα ingress για frontend/backend (path-based routing)
  - Ξεχωριστό ingress για Jenkins (`/jenkins` path)
  - TLS termination με cert-manager και Let's Encrypt
- **Persistent Volumes**:
  - PVC για Jenkins home, Postgres data, MinIO data, shared storage (frontend/backend artifacts)
- **Secrets/ConfigMaps**:
  - DB credentials, email credentials, app configs

## CI/CD (Jenkins)
### Jobs που δημιουργήθηκαν:
- **DevPets Pipeline**:
  - **Stage 1: Cleanup**: Διακοπή παλιών port-forwards, διαγραφή παλιών deployments/services
  - **Stage 2: Build**: Backend (Maven build), Frontend (npm build)
  - **Stage 3: Prepare Artifacts**: Αντιγραφή JAR/dist σε shared storage
  - **Stage 4: Update Manifests**: Ενημέρωση YAML για νέα artifacts/versions
  - **Stage 5: Deploy to Kubernetes**: `kubectl apply -f k8s/`, αναμονή για readiness
  - **Stage 6: Setup Port Forwarding (για local dev)**
  - **Stage 7: Verification**: Έλεγχος pods/services, υποδομών, εμφάνιση endpoints
- **Επιπλέον jobs**: Αυτόματο deploy σε κάθε push στο main branch, manual trigger για rollback/update

---

Αυτό το README καλύπτει συνοπτικά όλη την υποδομή, τις τεχνολογίες και τις διαδικασίες του DevPets project, χωρίς να περιλαμβάνει κώδικα ή YAML αρχεία. 