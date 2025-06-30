#!/bin/bash

# DevOps Pets Deployment Script
# This script runs all the necessary playbooks in the correct order

set -e  # Exit on any error

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN!]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERR!]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if we're in the right directory
check_directory() {
    if [ ! -f "ansible/deploy-all.yml" ]; then
        print_error "This script must be run from the Devpets-main directory"
        print_error "Current directory: $(pwd)"
        print_error "Expected files: ansible/deploy-all.yml"
        exit 1
    fi
}

# Function to check if ansible is available
check_ansible() {
    if ! command_exists ansible-playbook; then
        print_error "ansible-playbook is not installed or not in PATH"
        print_error "Please install Ansible first"
        exit 1
    fi
}

# Function to run playbook with error handling
run_playbook() {
    local playbook=$1
    local description=$2
    local optional=$3
    
    print_status "Running $description..."
    
    if ansible-playbook -i ansible/inventory.ini "ansible/$playbook"; then
        print_success "$description completed successfully"
    else
        if [ "$optional" = "true" ]; then
            print_warning "$description failed, but continuing..."
        else
            print_error "$description failed"
            exit 1
        fi
    fi
}

# Main execution
main() {
    echo "========================================"
    echo "DevOps Pets Deployment Script"
    echo "========================================"
    
    # Check prerequisites
    check_directory
    check_ansible
    
    print_status "Starting deployment process..."
    
    # Step 1: Validation (optional)
    if [ "$1" != "--skip-validation" ]; then
        run_playbook "validate-deployment.yml" "Validation" "true"
    else
        print_warning "Skipping validation as requested"
    fi
    
    # Step 2: Version check (optional)
    if [ "$1" != "--skip-version-check" ]; then
        run_playbook "check-versions.yml" "Version Check" "true"
    else
        print_warning "Skipping version check as requested"
    fi
    
    # Step 3: System setup (optional)
    if [ "$1" != "--skip-setup" ]; then
        run_playbook "setup-system.yml" "System Setup" "true"
    else
        print_warning "Skipping system setup as requested"
    fi
    
    # Step 4: Main deployment (required)
    print_status "Starting main deployment..."
    run_playbook "deploy-all.yml" "Main Deployment" "false"
    
    print_success "========================================"
    print_success "Deployment completed successfully!"
    print_success "========================================"
    print_success ""
    print_success "Services available at:"
    print_success "- Jenkins: http://localhost:8082"
    print_success "- MailHog: http://localhost:8025"
    print_success "- PostgreSQL: Running in cluster"
    print_success ""
    print_success "Next steps:"
    print_success "1. Access Jenkins to configure pipelines"
    print_success "2. Deploy backend and frontend via Jenkins"
    print_success "3. Test all services"
    print_success ""
    print_success "Useful commands:"
    print_success "- Check status: kubectl get all -n devops-pets"
    print_success "- View logs: kubectl logs -n devops-pets <pod-name>"
    print_success "- Stop forwarding: pkill -f 'kubectl port-forward'"
    print_success "========================================"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-validation    Skip the validation step"
    echo "  --skip-version-check Skip the version check step"
    echo "  --skip-setup         Skip the system setup step"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run full deployment"
    echo "  $0 --skip-validation  # Skip validation"
    echo "  $0 --skip-setup       # Skip system setup"
    echo ""
    echo "Note: This script must be run from the Devpets-main directory"
}

# Parse command line arguments
case "$1" in
    --help)
        show_help
        exit 0
        ;;
    --skip-validation|--skip-version-check|--skip-setup)
        main "$1"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac 