#!/bin/bash

# Stop DevOps Pets Deployment
# This script stops all running services

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

# Stop port forwarding
stop_port_forwards() {
    print_status "Stopping port forwarding..."
    pkill -f "kubectl port-forward" || true
    print_success "Port forwarding stopped"
}

# Stop kind cluster
stop_cluster() {
    print_status "Stopping Kind cluster..."
    if kind get clusters | grep -q "devops-pets"; then
        kind delete cluster --name devops-pets
        print_success "Kind cluster stopped"
    else
        print_warning "No Kind cluster found"
    fi
}

# Main stop function
main() {
    echo "========================================"
    echo "Stopping DevOps Pets Deployment"
    echo "========================================"
    
    stop_port_forwards
    stop_cluster
    
    print_success "All services stopped successfully"
}

main "$@" 