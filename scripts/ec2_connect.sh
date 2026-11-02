#!/bin/bash

set -euo pipefail

# Configuration
KEY_PATH="$HOME/Downloads/tut_ec2.pem""
SSH_USER="ubuntu"

# Get Elastic IP from Terraform
PUBLIC_IP=$(terraform output -raw server_public_ip)

echo "EC2 Public IP: $PUBLIC_IP"

# Connect to EC2
ssh -i "$KEY_PATH" "$SSH_USER@$PUBLIC_IP"