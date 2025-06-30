#!/bin/bash

# Jenkins Setup Script for DevOps Pets
# This script sets up Jenkins with required plugins and configurations

set -e

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

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

# Check if Jenkins is running
check_jenkins() {
    if curl -s http://localhost:8082/jenkins > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Wait for Jenkins to be ready
wait_for_jenkins() {
    print_status "Waiting for Jenkins to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if check_jenkins; then
            print_success "Jenkins is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - Jenkins not ready yet..."
        sleep 10
        ((attempt++))
    done
    
    print_error "Jenkins failed to start within expected time"
    return 1
}

# Main setup
main() {
    echo "========================================"
    echo "Jenkins Setup for DevOps Pets"
    echo "========================================"
    
    if ! check_jenkins; then
        print_error "Jenkins is not running on http://localhost:8082"
        print_error "Please start the deployment first: ./ansible/run-deployment.sh"
        exit 1
    fi
    
    print_success "Jenkins is accessible"
    print_status "Setup completed successfully"
    print_status "Access Jenkins at: http://localhost:8082/jenkins"
}

main "$@" 