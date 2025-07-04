# Τεκμηρίωση Έργου DevPets

Αυτό το έγγραφο περιγράφει την αρχιτεκτονική, το στήσιμο και τη ροή αυτοματοποίησης του DevPets.

## Δομή Έργου

Το έργο αποτελείται από δύο βασικά μέρη:

1. **Dpet**: Περιέχει τα Ansible playbooks για το στήσιμο όλης της υποδομής (Kind Kubernetes cluster, Jenkins, PostgreSQL, MailHog, MinIO, Ingress, κλπ).
2. **F-B-END**: Περιέχει τον κώδικα του backend (Spring Boot) και του frontend (Vue.js), μαζί με τα Kubernetes manifests και το Jenkinsfile για το CI/CD pipeline.

## Εξέλιξη Αυτοματοποίησης

Ο αρχικός στόχος ήταν να μπορεί ο developer να κάνει αλλαγή στον κώδικα και να τη βλέπει live, χωρίς χειροκίνητα βήματα μετά το αρχικό setup. Η βασική πρόκληση ήταν η αυτοματοποίηση του `kubectl port-forward` μετά από κάθε επιτυχημένο Jenkins build.

### Τελική Προσέγγιση: Kubernetes-Native Signals

- **Το Σήμα**: Το Jenkins pipeline, στο τέλος κάθε επιτυχημένου build, δημιουργεί ένα ConfigMap με label `build-complete=true` στο cluster.
- **Ο Watcher**: Ένα script (`build-watcher.py`) τρέχει στο host και παρακολουθεί το cluster για το ConfigMap.
- **Το Trigger**: Όταν εντοπιστεί το ConfigMap, το script τρέχει το playbook για port-forwarding.
- **Το Cleanup**: Το script διαγράφει το ConfigMap για να είναι έτοιμο για το επόμενο build.

**Πλεονεκτήματα:**
- Καμία ανάγκη για Jenkins API tokens ή χειροκίνητη παρέμβαση.
- Όλη η ροή είναι Kubernetes-native και ασφαλής.
- Ο developer βλέπει άμεσα το αποτέλεσμα κάθε build τοπικά.

## Η Πλήρως Αυτοματοποιημένη Ροή

1. **Αρχικό Setup:** Ο developer τρέχει ένα Ansible playbook που στήνει το cluster, κάνει deploy Jenkins και τις υπόλοιπες υπηρεσίες, και ξεκινά το `build-watcher.py` script στο host.
2. **Build Trigger:** Ο developer κάνει αλλαγές και τρέχει build στο Jenkins (π.χ. μέσω git push).
3. **CI/CD Pipeline:** Το Jenkins pipeline κάνει build και deploy τα applications στο cluster. Στο τέλος, δημιουργεί το ConfigMap-σήμα.
4. **Detection & Port-Forwarding:** Το watcher script εντοπίζει το σήμα και τρέχει το playbook για port-forwarding.
5. **Αυτόματη Πρόσβαση:** Ο developer έχει άμεση πρόσβαση στις εφαρμογές μέσω localhost.

## Αρχιτεκτονική Συστήματος

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Windows Host                            │
├─────────────────────────────────────────────────────────────────┤
│                    WSL2 (Linux Subsystem)                      │
├─────────────────────────────────────────────────────────────────┤
│                 Kind Kubernetes Cluster                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Jenkins Pod   │  │  Frontend Pod   │  │  Backend Pod    │ │
│  │                 │  │                 │  │                 │ │
│  │ - CI/CD Pipeline│  │ - Vue.js App    │  │ - Spring Boot   │ │
│  │ - Build Tools   │  │ - Nginx Proxy   │  │ - REST API      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  PostgreSQL Pod │  │  MailHog Pod    │  │ MetalLB/Ingress │ │
│  │                 │  │                 │  │                 │ │
│  │ - Database      │  │ - Email Testing │  │ - Load Balancing│ │
│  │ - Data Storage  │  │ - SMTP Server   │  │ - Traffic Route │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Network Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    External Access Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Browser   │  │   API Calls │  │   Jenkins   │            │
│  │ localhost:8081│  │ localhost:8080│  │ localhost:8082 │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Ingress Controller Layer                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              nginx-ingress-controller                       │ │
│  │  - Route / → frontend service                              │ │
│  │  - Route /api → backend service                            │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Service Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Frontend   │  │   Backend   │  │  PostgreSQL │            │
│  │ LoadBalancer│  │ LoadBalancer│  │ ClusterIP   │            │
│  │   :80       │  │   :8080     │  │   :5432     │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Pod Layer                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Frontend   │  │   Backend   │  │  PostgreSQL │            │
│  │   Pod       │  │    Pod      │  │    Pod      │            │
│  │ nginx:alpine│  │ openjdk:17  │  │ postgres:15 │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## Component Diagrams

### Application Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend (Vue.js)                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Router    │  │   Store     │  │ Components  │            │
│  │             │  │             │  │             │            │
│  │ - Navigation│  │ - State Mgmt│  │ - UI Elements│            │
│  │ - Auth Guard│  │ - User Data │  │ - Forms     │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   API Layer │  │   Views     │  │   Services  │            │
│  │             │  │             │  │             │            │
│  │ - HTTP Calls│  │ - Pages     │  │ - Business  │            │
│  │ - Auth Token│  │ - Templates │  │   Logic     │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Backend (Spring Boot)                   │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ Controllers │  │   Services  │  │ Repositories│            │
│  │             │  │             │  │             │            │
│  │ - REST APIs │  │ - Business  │  │ - Data      │            │
│  │ - Auth      │  │   Logic     │  │   Access    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Entities  │  │   Security  │  │   Config    │            │
│  │             │  │             │  │             │            │
│  │ - Data Model│  │ - JWT Auth  │  │ - App Props │            │
│  │ - Validation│  │ - Roles     │  │ - Database  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Database (PostgreSQL)                   │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │    Users    │  │   Animals   │  │  Requests   │            │
│  │             │  │             │  │             │            │
│  │ - User Data │  │ - Pet Info  │  │ - Adoption  │            │
│  │ - Roles     │  │ - Status    │  │   Requests  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### DevOps Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Jenkins Pipeline                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Checkout  │  │   Build     │  │   Deploy    │            │
│  │             │  │             │  │             │            │
│  │ - Git Repo  │  │ - Maven     │  │ - Kubernetes│            │
│  │ - Code      │  │ - NPM       │  │ - Services  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Setup     │  │   Verify    │  │   Ingress   │            │
│  │             │  │             │  │             │            │
│  │ - Kubeconfig│  │ - Health    │  │ - Routing   │            │
│  │ - LoadBalancer│ │ - Logs      │  │ - Access    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Infrastructure (Ansible)                    │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   System    │  │ Kubernetes  │  │   Jenkins   │            │
│  │   Setup     │  │   Setup     │  │   Setup     │            │
│  │             │  │             │  │             │            │
│  │ - Docker    │  │ - Kind      │  │ - Pipeline  │            │
│  │ - Tools     │  │ - Cluster   │  │ - RBAC      │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## Class Diagrams

### Backend Entity Classes

```
┌─────────────────────────────────────────────────────────────────┐
│                           User                                  │
├─────────────────────────────────────────────────────────────────┤
│ - id: Long                                                      │
│ - username: String                                              │
│ - email: String                                                 │
│ - password: String                                              │
│ - emailVerified: Boolean                                        │
│ - createdAt: LocalDateTime                                      │
│ - lastLogin: LocalDateTime                                      │
│ - verificationToken: String                                     │
│ - verificationTokenExpiry: LocalDateTime                        │
│ - roles: Set<Role>                                              │
├─────────────────────────────────────────────────────────────────┤
│ + register()                                                    │
│ + login()                                                       │
│ + verifyEmail()                                                 │
│ + updateProfile()                                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                           Role                                  │
├─────────────────────────────────────────────────────────────────┤
│ - id: Long                                                      │
│ - name: String                                                  │
│ - users: Set<User>                                              │
├─────────────────────────────────────────────────────────────────┤
│ + assignToUser()                                                │
│ + removeFromUser()                                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          Animal                                 │
├─────────────────────────────────────────────────────────────────┤
│ - id: Long                                                      │
│ - name: String                                                  │
│ - type: String                                                  │
│ - age: Integer                                                  │
│ - gender: Gender                                                │
│ - req: String                                                   │
│ - userId: Long                                                  │
│ - user: User                                                    │
├─────────────────────────────────────────────────────────────────┤
│ + createAnimal()                                                │
│ + updateAnimal()                                                │
│ + deleteAnimal()                                                │
│ + getAnimalsByUser()                                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Request                                 │
├─────────────────────────────────────────────────────────────────┤
│ - id: Long                                                      │
│ - name: String                                                  │
│ - type: String                                                  │
│ - age: Integer                                                  │
│ - gender: Gender                                                │
│ - adminApproved: Boolean                                        │
│ - docApproved: Boolean                                          │
├─────────────────────────────────────────────────────────────────┤
│ + submitRequest()                                               │
│ + approveRequest()                                              │
│ + rejectRequest()                                               │
└─────────────────────────────────────────────────────────────────┘
```

### Frontend Component Classes

```
┌─────────────────────────────────────────────────────────────────┐
│                        App.vue                                  │
├─────────────────────────────────────────────────────────────────┤
│ - router: Router                                                │
│ - store: Store                                                  │
│ - user: User                                                    │
├─────────────────────────────────────────────────────────────────┤
│ + mounted()                                                     │
│ + checkAuth()                                                   │
│ + logout()                                                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Router                                   │
├─────────────────────────────────────────────────────────────────┤
│ - routes: Array<Route>                                          │
│ - guards: Array<Guard>                                          │
├─────────────────────────────────────────────────────────────────┤
│ + beforeEach()                                                  │
│ + afterEach()                                                   │
│ + push()                                                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        Store                                    │
├─────────────────────────────────────────────────────────────────┤
│ - state: State                                                  │
│ - mutations: Object                                             │
│ - actions: Object                                               │
│ - getters: Object                                               │
├─────────────────────────────────────────────────────────────────┤
│ + commit()                                                      │
│ + dispatch()                                                    │
│ + getters                                                       │
└─────────────────────────────────────────────────────────────────┘
```

## Infrastructure Setup

### Devpets-main Infrastructure

The Devpets-main component provides the complete infrastructure setup using Ansible automation:

#### Key Components:
1. **Kind Kubernetes Cluster**: Local Kubernetes cluster for development
2. **Jenkins**: CI/CD pipeline automation
3. **PostgreSQL**: Database for the application
4. **MailHog**: Email testing service
5. **MetalLB**: Load balancer for external access
6. **Nginx Ingress**: Traffic routing and load balancing

#### Ansible Playbooks:
- **install-prerequisites.yml**: System dependencies and tools
- **setup-system.yml**: Docker, Kind, and Kubernetes setup
- **deploy-applications.yml**: Application deployment
- **deploy-all.yml**: Complete system deployment

### F-B-END Application

The F-B-END component contains the actual application code:

#### Backend (Spring Boot):
- **Controllers**: REST API endpoints
- **Services**: Business logic implementation
- **Repositories**: Data access layer
- **Entities**: Database models
- **Security**: JWT authentication and authorization

#### Frontend (Vue.js):
- **Components**: Reusable UI elements
- **Views**: Page components
- **Router**: Navigation and routing
- **Store**: State management
- **API**: HTTP client for backend communication

## Deployment Pipeline

### Jenkins Pipeline Stages

1. **Checkout**: Retrieve source code from Git repository
2. **Setup Kubeconfig**: Configure Kubernetes cluster access
3. **Setup LoadBalancer**: Install MetalLB for external access
4. **Complete Cleanup**: Remove existing deployments
5. **Apply RBAC**: Set up role-based access control
6. **Build Java Application**: Compile Spring Boot backend
7. **Build Frontend**: Build Vue.js frontend with Vite
8. **Deploy to Kubernetes**: Apply Kubernetes manifests
9. **Verify Deployment**: Confirm all components are running
10. **Setup Ingress**: Configure nginx-ingress for routing

### Pipeline Features:
- **Automated Build**: Maven for Java, NPM for Node.js
- **Shared Storage**: Persistent volumes for file sharing
- **Health Checks**: Pod readiness and liveness probes
- **Rolling Updates**: Zero-downtime deployments
- **Logging**: Centralized log collection
- **Monitoring**: Resource usage and performance metrics

## Technical Challenges and Solutions

### Challenge 1: Jenkins Running Inside Cluster
**Problem**: Jenkins runs inside the Kubernetes cluster, making port forwarding inaccessible from the host machine.

**Solution**: Implemented nginx-ingress controller for automatic traffic routing, eliminating the need for manual port forwarding.

### Challenge 2: File Sharing Between Jenkins and Pods
**Problem**: Jenkins needs to share built artifacts (JAR files, frontend dist) with application pods.

**Solution**: Implemented shared PersistentVolumeClaim (PVC) with init containers that copy files from shared storage to application pods.

### Challenge 3: Nginx Configuration Issues
**Problem**: Frontend nginx configuration had syntax errors and wasn't properly mounted.

**Solution**: Created ConfigMap with correct nginx configuration and ensured proper volume mounting in frontend deployment.

### Challenge 4: LoadBalancer External Access
**Problem**: Kind cluster doesn't have LoadBalancer controller by default.

**Solution**: Installed MetalLB LoadBalancer controller and configured IP address pools for external access.

### Challenge 5: Database Connectivity
**Problem**: Backend application needs to connect to PostgreSQL database.

**Solution**: Configured database connection using Kubernetes service discovery and environment variables.

### Challenge 6: RBAC Permissions
**Problem**: Jenkins pods needed proper permissions to create and manage Kubernetes resources.

**Solution**: Created custom ServiceAccount, Role, and RoleBinding with appropriate permissions for the devops-pets namespace.

### Challenge 7: Frontend-Backend Communication
**Problem**: Frontend needs to communicate with backend API through nginx proxy.

**Solution**: Configured nginx reverse proxy to route /api/ requests to backend service while serving frontend static files.

### Challenge 8: Persistent Data Storage
**Problem**: Database and Jenkins data need to persist across pod restarts.

**Solution**: Implemented PersistentVolumes and PersistentVolumeClaims for PostgreSQL and Jenkins data directories.

## Directory Structure

### Devpets-main Structure

```
Devpets-main/
├── ansible/                    # Ansible automation scripts
│   ├── tasks/                  # Individual task files
│   ├── inventory.ini           # Host inventory
│   ├── ansible.cfg             # Ansible configuration
│   └── requirements.yml        # Ansible dependencies
├── k8s/                        # Kubernetes manifests
│   ├── jenkins/                # Jenkins deployment
│   ├── postgres/               # PostgreSQL deployment
│   └── mailhog/                # MailHog deployment
├── jenkins_home/               # Jenkins persistent data
├── docker-compose.yml          # Local development setup
├── kind-config.yaml            # Kind cluster configuration
└── README.md                   # Project documentation
```

### F-B-END Structure

```
F-B-END/
├── Ask/                        # Spring Boot backend
│   ├── src/main/java/          # Java source code
│   ├── src/main/resources/     # Configuration files
│   └── pom.xml                 # Maven configuration
├── frontend/                   # Vue.js frontend
│   ├── src/                    # Vue.js source code
│   ├── public/                 # Static assets
│   └── package.json            # NPM configuration
├── k8s/                        # Kubernetes manifests
│   ├── backend/                # Backend deployment
│   ├── frontend/               # Frontend deployment
│   └── shared-storage.yaml     # Shared storage configuration
├── Jenkinsfile                 # CI/CD pipeline
└── README.md                   # Project documentation
```

## Usage Instructions

### Prerequisites
1. Windows 10/11 with WSL2 enabled
2. Docker Desktop installed
3. Git installed
4. At least 8GB RAM available

### Initial Setup
1. Clone both repositories:
   ```bash
   git clone <devpets-main-repo>
   git clone <f-b-end-repo>
   ```

2. Navigate to Devpets-main and run deployment:
   ```bash
   cd Devpets-main
   ./deploy
   ```

3. Wait for infrastructure to be ready (5-10 minutes)

### Application Deployment
1. Navigate to F-B-END directory
2. Access Jenkins at http://localhost:8082
3. Create new pipeline job pointing to F-B-END repository
4. Run the pipeline
5. Access application at http://localhost:8081

### Access Points (Updated)
- **Frontend Application**: http://localhost:8081
- **Backend API**: http://localhost:8080/api
- **Jenkins**: http://localhost:8082
- **MailHog**: http://localhost:8025
- **PostgreSQL**: localhost:5432 (internal only)

### Troubleshooting
1. **Check pod status**: `kubectl get pods -n devops-pets`
2. **View logs**: `kubectl logs <pod-name> -n devops-pets`
3. **Check services**: `kubectl get services -n devops-pets`
4. **Check ingress**: `kubectl get ingress -n devops-pets`

### Maintenance
1. **Update applications**: Run Jenkins pipeline
2. **Scale deployments**: `kubectl scale deployment <name> --replicas=<number>`
3. **Backup database**: `kubectl exec -it <postgres-pod> -- pg_dump -U petuser petdb > backup.sql`
4. **Restore database**: `kubectl exec -i <postgres-pod> -- psql -U petuser petdb < backup.sql`

## Summary of New Flow
- Deploy infrastructure and applications with Ansible and Jenkins.
- Ansible waits for pods to be stable, then starts port forwarding:
  - Frontend: http://localhost:8081
  - Backend API: http://localhost:8080/api
- Users access the system via these URLs. No manual port forwarding is needed.

## Conclusion

This project demonstrates a complete DevOps implementation with:
- **Infrastructure as Code**: Ansible automation for infrastructure setup
- **Container Orchestration**: Kubernetes for application deployment
- **CI/CD Pipeline**: Jenkins for automated build and deployment
- **Microservices Architecture**: Separate frontend and backend services
- **Load Balancing**: MetalLB and nginx-ingress for traffic management
- **Persistent Storage**: Database and Jenkins data persistence
- **Security**: RBAC and JWT authentication
- **Monitoring**: Health checks and logging

The system provides a robust foundation for pet adoption management with automated deployment, scaling, and maintenance capabilities.

## Automated Workflow

The core of this project is a fully automated CI/CD pipeline that takes code changes and deploys them to a local Kubernetes cluster, making them accessible to the developer without manual intervention.

Here is the sequence of events:

1.  **Initial Setup:** The developer runs a single Ansible playbook to create the local Kubernetes cluster and deploy all the necessary services (Jenkins, etc.). This playbook also starts a background polling script on the developer's machine.
2.  **Code Push & Build:** When new code is pushed (or a build is manually triggered), the Jenkins pipeline inside the cluster checks out the code.
3.  **Build & Deploy:** Jenkins builds the frontend and backend applications. It then uses `kubectl` to apply the Kubernetes manifests, deploying the new versions of the applications. The build artifacts (JAR and dist files) are shared with the application pods using a shared Persistent Volume.
4.  **Polling & Port-Forwarding:** The background script on the developer's host machine continuously polls the Jenkins API to check for the completion of a build.
5.  **Success Detection:** Once the script detects a successful build, it triggers a second, smaller Ansible playbook.
6.  **Automatic Access:** This second playbook waits for the new application pods to be stable and running, and then automatically starts `kubectl port-forward`. This makes the frontend and backend services immediately available on the developer's `localhost`.

## Getting Started: One-Time Setup

To get the project running, follow these steps. This is a **one-time setup** for each developer.

### 1. Prerequisites

Ensure you have the following tools installed on your machine:
*   Ansible (`pip install ansible`)
*   Python `requests` library (`pip install requests`)
*   Docker
*   Kind
*   Kubectl

### 2. Run the Main Deployment

Execute the main Ansible playbook to create the cluster and all services. This command does everything for you.

```bash
ansible-playbook Devpets-main/ansible/deploy-all.yml
```

This will also start the background polling script that listens for Jenkins builds.

### 3. Configure Jenkins and Get API Token

The polling script needs an API token to securely communicate with Jenkins.

1.  **Access Jenkins:** Once the playbook is running, Jenkins will be available at `http://localhost:8082`.
2.  **Initial Password:** Get the initial admin password by running:
    ```bash
    kubectl exec -n devops-pets svc/jenkins -c jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
    ```
3.  **Setup Jenkins:**
    *   Complete the initial setup wizard.
    *   Navigate to **Manage Jenkins > Configure Global Security**.
    *   Select **"Matrix-based security"**.
    *   Give the **"admin"** user all permissions.
    *   **IMPORTANT:** Ensure **"Anonymous Users"** have the **"Overall/Read"** permission. This is necessary for the initial anonymous access by the polling script before you configure a token.
    *   Save the configuration.
4.  **Create API Token:**
    *   Click on your username (e.g., "admin") in the top-right corner.
    *   Go to **Configure**.
    *   Under the **"API Token"** section, click **"Add new Token"**.
    *   Give it a name (e.g., `polling-script-token`) and click **"Generate"**.
    *   **Copy the generated token immediately.** You will not be able to see it again.

### 4. Set the Environment Variable

The polling script reads the token from an environment variable named `JENKINS_API_TOKEN`.

**Windows (PowerShell):**
```powershell
$env:JENKINS_API_TOKEN="your_copied_api_token"
```
*Note: To make this permanent, you'll need to add it to your PowerShell profile or set it via the System Properties.*

**Linux/macOS:**
```bash
export JENKINS_API_TOKEN="your_copied_api_token"
```
*Note: Add this line to your `~/.bashrc`, `~/.zshrc`, or equivalent shell profile file to make it permanent.*

**The polling script will automatically pick up this token on its next run.**

## Daily Workflow

After the one-time setup, your daily workflow is simple:

1.  Make changes to the frontend or backend code in the `F-B-END` directory.
2.  Trigger a build in Jenkins (either by pushing to your Git remote or by starting one manually in the UI).
3.  Wait for the build to complete.
4.  The polling script will detect the new build and automatically run `port-forward`.
5.  Access your applications:
    *   **Frontend:** `http://localhost:8081`
    *   **Backend API:** `http://localhost:8080`

You do not need to run any `kubectl` or `ansible` commands manually after the initial setup. 

## Προβλήματα που Αντιμετωπίσαμε και Πώς Λύθηκαν

1. **Σφάλματα στα secrets/email credentials:**
   - Το backend έπαιρνε λάθος ή κενές μεταβλητές περιβάλλοντος για το email. Η λύση ήταν να δημιουργηθεί σωστά το Kubernetes secret και να γίνει σωστή αναφορά στο deployment YAML.

2. **MinIO credentials mismatch:**
   - Το backend είχε διαφορετικά credentials από το MinIO pod. Η λύση ήταν να συγχρονιστούν τα secrets και να γίνει redeploy.

3. **Λάθος όνομα bucket στο MinIO:**
   - Το backend ζητούσε bucket που δεν υπήρχε. Η λύση ήταν να εναρμονιστεί το όνομα bucket στο backend config και στο MinIO deployment.

4. **Database column length (image URL):**
   - Το presigned URL του MinIO ήταν μεγαλύτερο από το varchar(255) της βάσης. Η λύση ήταν να αλλάξει ο τύπος της στήλης σε TEXT και να ενημερωθεί το JPA entity.

5. **Port-forwarding robustness:**
   - Το script για port-forwarding έπρεπε να είναι ανθεκτικό σε disconnects. Προστέθηκε loop και έλεγχος για όλα τα services (Jenkins, Mailhog, MinIO, backend, frontend, Postgres).

6. **Ingress/Network routing:**
   - Εξασφαλίστηκε ότι το Ingress controller είναι πάντα εγκατεστημένο και σωστά ρυθμισμένο μέσω Ansible και manifests.

7. **Αυτόματη ανίχνευση επιτυχούς build:**
   - Η μετάβαση από polling του Jenkins API σε Kubernetes-native signal (ConfigMap) έκανε τη ροή πιο αξιόπιστη και ασφαλή.

8. **Ενσωμάτωση MinIO:**
   - Προστέθηκε MinIO ως αντικειμενοθήκη για τα αρχεία εικόνων, με σωστή διαχείριση credentials και bucket.

9. **Ασφάλεια και RBAC:**
   - Όλα τα pods και services έχουν περιορισμένα permissions μέσω RBAC και τα secrets περνάνε μόνο μέσω Kubernetes secrets.

10. **Ευκολία για τον developer:**
    - Όλη η ροή είναι πλέον one-command, χωρίς χειροκίνητα βήματα μετά το setup.

---

(Τέλος αρχείου. Όλες οι ενότητες, διαγράμματα και flows διατηρούνται όπως στο αρχικό, απλώς μεταφρασμένα και ενημερωμένα.) 