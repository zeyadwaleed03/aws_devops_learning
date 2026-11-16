#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TERRAFORM_DIR="$PROJECT_DIR/terraform"
ANSIBLE_DIR="$PROJECT_DIR/ansible"
ENV_FILE="$PROJECT_DIR/scripts/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing $ENV_FILE. Copy scripts/.env.example to scripts/.env and configure it." >&2
    exit 1
fi

# The playbook reads these values from Ansible's controller environment.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${DUCKDNS_TOKEN:-}" || "$DUCKDNS_TOKEN" == "your-duckdns-token" || "$DUCKDNS_TOKEN" == "YOUR_DUCKDNS_TOKEN_HERE" ]]; then
    echo "Set a real DUCKDNS_TOKEN in scripts/.env before deploying." >&2
    exit 1
fi

if [[ -z "${DUCKDNS_DOMAIN:-}" || -z "${LETSENCRYPT_EMAIL:-}" || "$LETSENCRYPT_EMAIL" == "your-email@example.com" ]]; then
    echo "Set DUCKDNS_DOMAIN and a real LETSENCRYPT_EMAIL in scripts/.env before deploying." >&2
    exit 1
fi

# Retrieve Elastic IP
PUBLIC_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw server_public_ip)

if [[ -z "$PUBLIC_IP" ]]; then
    echo "Error: Terraform returned an empty public IP"
    exit 1
fi

echo "EC2 Public IP: $PUBLIC_IP"

# Generate inventory
sed "s|__SERVER_PUBLIC_IP__|$PUBLIC_IP|g" \
    "$ANSIBLE_DIR/inventory.ini.tpl" \
    > "$ANSIBLE_DIR/inventory.ini"

echo "Inventory generated successfully"

# Execute playbook
ansible-playbook \
    -i "$ANSIBLE_DIR/inventory.ini" \
    "$ANSIBLE_DIR/playbook.yml"