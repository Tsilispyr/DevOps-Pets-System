# Dpet (DevPets Infrastructure & DevOps)

## Περιγραφή
Το Dpet είναι το infrastructure και DevOps κομμάτι του συστήματος DevPets. Περιλαμβάνει όλη την αυτοματοποίηση για:
- Δημιουργία και διαχείριση Kubernetes cluster (Kind)
- Αυτόματη εγκατάσταση Jenkins (CI/CD), PostgreSQL, MailHog, MinIO, Ingress Controller
- **HTTPS/SSL με cert-manager και Let's Encrypt**
- **Cloud deployment με Azure VM και AKS**
- Διαχείριση persistent storage (PVCs)
- Port-forwarding και developer tooling

Όλα γίνονται με Ansible playbooks και Kubernetes manifests, ώστε να στήνεται τοπικά, σε VM, ή στο cloud με ένα command.

## Σύνδεση με F-B-END
Το Dpet στήνει όλη την υποδομή πάνω στην οποία τρέχει το F-B-END (backend & frontend εφαρμογή). Η επικοινωνία γίνεται μέσω Kubernetes services και Ingress. Το deployment του F-B-END γίνεται αυτόματα μέσω Jenkins pipeline.

## Δομή
```
Dpet/
├── ansible/                # Ansible playbooks & tasks
│   ├── deploy-all.yml      # Κύριο playbook: στήνει όλο το cluster & services
│   ├── ...                # Άλλα playbooks για setup, validation, κλπ
│   └── tasks/             # Εξειδικευμένα tasks για κάθε υπηρεσία
├── k8s/                   # Kubernetes manifests (Jenkins, Postgres, Mailhog, κλπ)
├── start-port-forwards.sh # Script για αυτόματο port-forwarding
├── kind-config.yaml       # Kind cluster config
├── docker-compose.yml     # (Προαιρετικό) Local dev setup
└── README.md
```

## Βασικά Playbooks & Scripts
- **deploy-all.yml**: Εκτελεί όλη τη ροή (setup, cluster, cert-manager, Jenkins, DB, Mailhog, Ingress, MinIO, HTTPS)
- **setup-system.yml**: Εγκαθιστά Docker, Kind, kubectl, κλπ
- **deploy-applications.yml**: Deploy μόνο των εφαρμογών (χωρίς cluster recreation)
- **start-port-forwards.sh**: Κρατάει ενεργά τα port-forwards για όλα τα services (Jenkins, Mailhog, MinIO, backend, frontend, Postgres)
- **Cloud deployment**: Αυτόματη εγκατάσταση σε Azure VM με k3s και HTTPS

## Αρχικό Setup
1. **Προαπαιτούμενα**:
   - Windows 10/11 με WSL2
   - Docker Desktop
   - Python 3, Ansible
   - Git
2. **Εκτέλεση**:
   ```bash
   cd Dpet
   chmod +x deploy.sh
   ./deploy.sh
   ```
'Η εάν υπάρχει ήδη ansible 
```bash
ansible-playbook ansible/deploy-all.yml
 ```
   Αυτό στήνει όλο το cluster, Jenkins, DB, Mailhog, Ingress, και ξεκινά το port-forwarding.

## Καθημερινή Χρήση

### Local Development
- Κάνε αλλαγές στον κώδικα (στο F-B-END)
- Τρέξε pipeline στο Jenkins (http://localhost:8082)
- Πρόσβαση σε:
  - Frontend: http://localhost:8081
  - Backend API: http://localhost:8080/api
  - Jenkins: http://localhost:8082
  - MailHog: http://localhost:8025
  - MinIO: http://localhost:9000

### Cloud Deployment (Production)
- **HTTPS URLs** (μετά από DNS setup):
  - Frontend: https://pet-system.com
  - Jenkins: https://jenkins.pet-system.com
- **Port-forwarding** για developer tools:
  - Backend API: http://localhost:8080/api
  - MailHog: http://localhost:8025
  - MinIO Console: http://localhost:9000

## Troubleshooting
- Έλεγξε pods: `kubectl get pods -n devops-pets`
- Logs: `kubectl logs <pod> -n devops-pets`
- Services: `kubectl get svc -n devops-pets`
- Ingress: `kubectl get ingress -n devops-pets`
- **HTTPS/Certificates**: `kubectl get certificates -n devops-pets`
- **Cert-manager**: `kubectl get pods -n cert-manager`
- **Port-forwarding**: `ps aux | grep "kubectl port-forward"`

## Σημειώσεις
- Όλη η υποδομή είναι ephemeral: κάθε deploy δημιουργεί νέο cluster.
- Τα credentials και secrets περνάνε μέσω Kubernetes secrets.
- **HTTPS certificates** ανανεώνονται αυτόματα από Let's Encrypt.
- **Cloud deployment** υποστηρίζεται με Azure VM και AKS.
- Για πλήρη ροή και αρχιτεκτονική, δες το `FULL_PROJECT_OVERVIEW.md`.



 
