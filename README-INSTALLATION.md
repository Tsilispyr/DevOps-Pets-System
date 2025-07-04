# Οδηγίες Εγκατάστασης & Χρήσης / Installation & Usage Instructions

Πλήρες Deployment με μια γραμμή στο terminal: curl -L https://github.com/Tsilispyr/DevOps-Pets-System/archive/refs/heads/main.zip -o DevOps-Pets-System-main.zip && unzip DevOps-Pets-System-main.zip && cd DevOps-Pets-System-main && chmod +x deploy.sh && ./deploy.sh


## Ελληνικά

### Προαπαιτούμενα
- **Docker** (>= 20.x)
- **Docker Compose**
- **Ansible** (>= 2.9)
- **kubectl**
- **kind** (Kubernetes in Docker)
- **Java 17+** (για το backend)
- **Node.js & npm** (για το frontend)

> Τα περισσότερα εργαλεία εγκαθίστανται αυτόματα μέσω του Ansible playbook, αν δεν υπάρχουν ήδη.

### Βήματα Εγκατάστασης

1. **Κλωνοποίηση του αποθετηρίου**
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Εκτέλεση του Ansible Playbook**
   ```bash
   cd Dpet/ansible
   ansible-playbook -i inventory.ini deploy-all.yml
   ```
   Αυτό το playbook:
   - Εγκαθιστά τα απαραίτητα εργαλεία (docker, kind, kubectl, κλπ)
   - Δημιουργεί το Kubernetes cluster
   - Αναπτύσσει τις υπηρεσίες: Postgres, Jenkins, Mailhog, backend, frontend
   - Ρυθμίζει τα port-forwards για πρόσβαση στις υπηρεσίες

3. **Πρόσβαση στις Υπηρεσίες**
   - **Jenkins:** http://localhost:8080
   - **Mailhog:** http://localhost:8025
   - **Backend API:** http://localhost:8081
   - **Frontend:** http://localhost:8082

4. **Ρύθμιση Email (προαιρετικό)**
   - Για πραγματική αποστολή email, ενημερώστε το `application.properties` του backend με τα στοιχεία SMTP του παρόχου σας (π.χ. Gmail).

5. **Τερματισμός/Καθαρισμός**
   - Για να σταματήσετε το cluster και τις υπηρεσίες:
     ```bash
     cd Dpet/ansible
     ./stop-deployment.sh
     ```

---

## English

### Prerequisites
- **Docker** (>= 20.x)
- **Docker Compose**
- **Ansible** (>= 2.9)
- **kubectl**
- **kind** (Kubernetes in Docker)
- **Java 17+** (for backend)
- **Node.js & npm** (for frontend)

> Most tools are auto-installed by the Ansible playbook if missing.

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Run the Ansible Playbook**
   ```bash
   cd Dpet/ansible
   ansible-playbook -i inventory.ini deploy-all.yml
   ```
   This playbook:
   - Installs required tools (docker, kind, kubectl, etc.)
   - Creates the Kubernetes cluster
   - Deploys services: Postgres, Jenkins, Mailhog, backend, frontend
   - Sets up port-forwards for service access

3. **Access Services**
   - **Jenkins:** http://localhost:8080
   - **Mailhog:** http://localhost:8025
   - **Backend API:** http://localhost:8081
   - **Frontend:** http://localhost:8082

4. **Email Setup (optional)**
   - For real email sending, update the backend's `application.properties` with your SMTP provider's credentials (e.g., Gmail).

5. **Shutdown/Cleanup**
   - To stop the cluster and services:
     ```bash
     cd Dpet/ansible
     ./stop-deployment.sh
     ```

---

_Για περισσότερες πληροφορίες ή βοήθεια, επικοινωνήστε με τον διαχειριστή του έργου._
_For more information or help, contact the project administrator._ 