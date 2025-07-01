# Ansible Scripts - Αυτοματισμοί Υποδομής (Dpet)

## Επισκόπηση

Ο φάκελος αυτός περιέχει όλα τα Ansible playbooks και tasks που αυτοματοποιούν το στήσιμο της υποδομής του DevPets. Εδώ γίνεται όλη η εγκατάσταση εργαλείων, η δημιουργία Kubernetes cluster (Kind), και το deployment των βασικών υπηρεσιών (Jenkins, PostgreSQL, Mailhog, MinIO, Ingress).

## Δομή Φακέλου
```
ansible/
├── tasks/                      # Εξειδικευμένα tasks για κάθε υπηρεσία/εργαλείο
│   ├── install-*.yml           # Εγκατάσταση εργαλείων (docker, kind, kubectl, κλπ)
│   ├── create-*.yml            # Δημιουργία cluster, namespace
│   ├── deploy-*.yml            # Deploy Jenkins, Postgres, Mailhog
│   └── ...
├── inventory.ini               # Ορισμός hosts (πάντα local)
├── ansible.cfg                 # Ρυθμίσεις Ansible
├── requirements.yml            # Εξαρτήσεις Ansible (collections)
├── deploy-all.yml              # Κύριο playbook: στήνει όλη την υποδομή
├── install-prerequisites.yml   # Εγκατάσταση προαπαιτούμενων εργαλείων
├── setup-system.yml            # Δημιουργία cluster, namespace, base config
├── deploy-applications.yml     # Deploy μόνο των εφαρμογών
├── validate-deployment.yml     # Έλεγχος επιτυχίας deployment
├── check-versions.yml          # Έλεγχος εκδόσεων εργαλείων
├── run-deployment.sh           # Script για εύκολη εκτέλεση deployment
└── stop-deployment.sh          # Script για cleanup/stop
```

## Βασικά Playbooks
- **deploy-all.yml**: Εκτελεί όλη τη ροή (έλεγχος prerequisites, setup, cluster, Jenkins, DB, Mailhog, Ingress, MinIO)
- **install-prerequisites.yml**: Εγκαθιστά όλα τα απαραίτητα εργαλεία (docker, kind, kubectl, κλπ)
- **setup-system.yml**: Δημιουργεί το Kind cluster, namespace, base config, MetalLB
- **deploy-applications.yml**: Deploy μόνο των υπηρεσιών (χωρίς να ξαναστήσει το cluster)
- **validate-deployment.yml**: Ελέγχει ότι όλα τα pods/services είναι healthy
- **check-versions.yml**: Ελέγχει αν οι εκδόσεις εργαλείων είναι συμβατές

## Χρήση
- **Ολικό deployment**:
  ```bash
  ./run-deployment.sh
  # ή
  ansible-playbook -i inventory.ini deploy-all.yml
  ```
- **Βήμα-βήμα**:
  ```bash
  ansible-playbook -i inventory.ini install-prerequisites.yml
  ansible-playbook -i inventory.ini setup-system.yml
  ansible-playbook -i inventory.ini deploy-applications.yml
  ```
- **Έλεγχος**:
  ```bash
  ansible-playbook -i inventory.ini validate-deployment.yml
  ansible-playbook -i inventory.ini check-versions.yml
  ```
- **Καθαρισμός/stop**:
  ```bash
  ./stop-deployment.sh
  ```

## Troubleshooting
- Αν κάποιο βήμα αποτύχει, δες τα logs του Ansible ή των pods (`kubectl logs ...`).
- Για verbose output: `ansible-playbook ... -vvv`
- Για συγκεκριμένο task: `ansible-playbook ... --tags "jenkins"`

## Σημειώσεις
- Όλα τα tasks είναι idempotent (μπορούν να τρέξουν ξανά χωρίς πρόβλημα)
- Τα credentials περνάνε μέσω Kubernetes secrets
- Για πλήρη αρχιτεκτονική, δες το `FULL_PROJECT_OVERVIEW.md` 