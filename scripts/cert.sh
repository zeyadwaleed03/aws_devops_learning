#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
SCRIPT_PARENT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "$SCRIPT_PARENT/docker-compose.yaml" ]]; then
    APP_DIR="$SCRIPT_PARENT"
elif [[ -f "$SCRIPT_PARENT/app/docker-compose.yaml" ]]; then
    APP_DIR="$SCRIPT_PARENT/app"
else
    echo "Could not find docker-compose.yaml next to scripts or in the app directory." >&2
    exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing ${ENV_FILE}. Copy scripts/.env.example to scripts/.env and configure it." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

: "${DUCKDNS_TOKEN:?DUCKDNS_TOKEN is required}"
: "${DUCKDNS_DOMAIN:?DUCKDNS_DOMAIN is required}"
: "${LETSENCRYPT_EMAIL:?LETSENCRYPT_EMAIL is required}"

if [[ "$DUCKDNS_TOKEN" == "YOUR_DUCKDNS_TOKEN_HERE" || "$DUCKDNS_TOKEN" == "your-duckdns-token" ]]; then
    echo "Configure a real DuckDNS token in scripts/.env before continuing." >&2
    exit 1
fi

MY_IP=$(curl -4 -fsS https://checkip.amazonaws.com | tr -d '[:space:]')
RESPONSE=$(curl -fsS --get \
    --data-urlencode "domains=${DUCKDNS_DOMAIN%.duckdns.org}" \
    --data-urlencode "token=$DUCKDNS_TOKEN" \
    --data-urlencode "ip=$MY_IP" \
    https://www.duckdns.org/update)

if [[ "$RESPONSE" != "OK" ]]; then
    echo "DuckDNS update failed: $RESPONSE" >&2
    exit 1
fi
echo "DuckDNS updated: $DUCKDNS_DOMAIN -> $MY_IP"

mkdir -p /opt/certbot/{www,conf,work,logs}

sudo certbot certonly \
    --webroot \
    -w /opt/certbot/www \
    --config-dir /opt/certbot/conf \
    --work-dir /opt/certbot/work \
    --logs-dir /opt/certbot/logs \
    --non-interactive \
    --agree-tos \
    --email "$LETSENCRYPT_EMAIL" \
    -d "$DUCKDNS_DOMAIN"

sed "s|__DUCKDNS_DOMAIN__|$DUCKDNS_DOMAIN|g" \
    "$APP_DIR/nginx-ssl.conf.template" > "$APP_DIR/nginx.conf"

sudo mkdir -p /opt/certbot/conf/renewal-hooks/deploy
sudo tee /opt/certbot/conf/renewal-hooks/deploy/reload-nginx.sh >/dev/null <<EOF
#!/bin/bash
set -e
docker compose -f "$APP_DIR/docker-compose.yaml" restart webserver
EOF
sudo chmod 0755 /opt/certbot/conf/renewal-hooks/deploy/reload-nginx.sh

cd "$APP_DIR"
sudo docker compose restart webserver

echo "HTTPS is configured for https://$DUCKDNS_DOMAIN"
