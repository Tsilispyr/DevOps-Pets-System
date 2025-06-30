#!/bin/bash

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

# 1. Check if ansible is installed
if ! command -v ansible-playbook >/dev/null 2>&1; then
    print_warning "Ansible not found. Installing..."
    # Για Ubuntu/Debian:
    sudo apt update
    sudo apt install -y ansible
    print_success "Ansible installed successfully."
else
    print_success "Ansible is already installed."
fi

# 2. Run the playbook
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
print_status "Running Ansible playbook..."
ansible-playbook -i ansible/inventory.ini ansible/deploy-all.yml 