#!/bin/bash

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TF_DIR="$PROJECT_ROOT/terraform"
KEY_PATH="$HOME/Downloads/tut_ec2.pem"
SSH_USER="ubuntu"

# Get Elastic IP from Terraform
PUBLIC_IP=$(terraform -chdir="$TF_DIR" output -raw server_public_ip)

echo "EC2 Public IP: $PUBLIC_IP"

# Connect to EC2
ssh -i "$KEY_PATH" "$SSH_USER@$PUBLIC_IP"
