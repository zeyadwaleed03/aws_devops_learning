#!/bin/bash

set -euo pipefail

TFVARS_FILE="./terraform/terraform.tfvars"
VARIABLE="security_group_cidr_ingress_ssh"

# Extract public IP
MY_IP=$(curl -4 -fsS https://checkip.amazonaws.com | tr -d '[:space:]')
MY_CIDR="${MY_IP}/32"

# Check whether variable exists
if grep -qE "^[[:space:]]*${VARIABLE}[[:space:]]*=" "$TFVARS_FILE"; then

    # Extract existing value
    CURRENT_CIDR=$(grep -E "^[[:space:]]*${VARIABLE}[[:space:]]*=" "$TFVARS_FILE" |
        tail -n 1 |
        sed -E 's/^[^=]*=[[:space:]]*//; s/[[:space:]]*#.*$//; s/^["'\'']|["'\'']$//g')

    if [[ "$CURRENT_CIDR" == "$MY_CIDR" ]]; then
        echo "SSH ingress IP is already up to date: $MY_CIDR"
        
    else
        sed -i -E \
            "s|^[[:space:]]*${VARIABLE}[[:space:]]*=.*|${VARIABLE} = \"${MY_CIDR}\"|" \
            "$TFVARS_FILE"

        echo "Updated SSH ingress IP: $CURRENT_CIDR -> $MY_CIDR"
    fi

else
    echo "${VARIABLE} = \"${MY_CIDR}\"" >> "$TFVARS_FILE"
    echo "Added SSH ingress IP: $MY_CIDR"
fi
