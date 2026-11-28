#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TFVARS_FILE="$PROJECT_DIR/terraform/terraform.tfvars"
REMOVE_RUNNER=false

if [[ "${1:-}" == "--remove-runner" ]]; then
    REMOVE_RUNNER=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--remove-runner]" >&2
    exit 2
fi

is_ipv4() {
    local address="$1"
    local octet
    local -a octets

    [[ "$address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    IFS='.' read -r -a octets <<< "$address"
    for octet in "${octets[@]}"; do
        ((10#$octet <= 255)) || return 1
    done
}

ADMIN_IP="${ADMIN_SSH_IP:-}"
if [[ "$ADMIN_IP" == */32 ]]; then
    ADMIN_IP="${ADMIN_IP%/32}"
fi
if ! is_ipv4 "$ADMIN_IP"; then
    echo "Set ADMIN_SSH_IP to your public IPv4 address (optionally with /32)." >&2
    exit 1
fi

RUNNER_IP=""
if [[ "$REMOVE_RUNNER" != true ]]; then
    RUNNER_IP="$(curl -4 -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"
    if ! is_ipv4 "$RUNNER_IP"; then
        echo "Could not determine a valid public IPv4 address for this runner." >&2
        exit 1
    fi
fi

TEMP_FILE="$(mktemp "$PROJECT_DIR/terraform/terraform.tfvars.XXXXXX")"
trap 'rm -f -- "$TEMP_FILE"' EXIT

if [[ -f "$TFVARS_FILE" ]]; then
    awk '
        !/^[[:space:]]*security_group_cidr_ingress_ssh(_runner)?[[:space:]]*=/
    ' "$TFVARS_FILE" > "$TEMP_FILE"
fi

{
    printf 'security_group_cidr_ingress_ssh = "%s/32"\n' "$ADMIN_IP"
    if [[ "$REMOVE_RUNNER" != true && "$RUNNER_IP" != "$ADMIN_IP" ]]; then
        printf 'security_group_cidr_ingress_ssh_runner = "%s/32"\n' "$RUNNER_IP"
    fi
} >> "$TEMP_FILE"

chmod 600 "$TEMP_FILE"
mv "$TEMP_FILE" "$TFVARS_FILE"
terraform fmt "$TFVARS_FILE"

if [[ "$REMOVE_RUNNER" == true ]]; then
    echo "Updated SSH ingress configuration to retain only the admin IP."
elif [[ "$RUNNER_IP" == "$ADMIN_IP" ]]; then
    echo "Admin and runner IPs match; only one SSH ingress rule is needed."
else
    echo "Updated SSH ingress configuration for the admin and current runner."
fi
