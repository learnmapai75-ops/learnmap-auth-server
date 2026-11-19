#!/bin/bash
set -euo pipefail

echo "=== Keycloak Deployment on Auth Server ==="

# Generate secure passwords
KC_DB_PASSWORD=$(openssl rand -base64 32)
KC_ADMIN_PASSWORD=$(openssl rand -base64 32)
WEB_CLIENT_SECRET=$(openssl rand -base64 32)
API_CLIENT_SECRET=$(openssl rand -base64 32)
ADMIN_CLIENT_SECRET=$(openssl rand -base64 32)

# Create .env file
cat > .env <<EOF
# Keycloak
KC_DB_PASSWORD=${KC_DB_PASSWORD}
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=${KC_ADMIN_PASSWORD}

# Database
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=${KC_DB_PASSWORD}

# Clients
WEB_CLIENT_SECRET=${WEB_CLIENT_SECRET}
API_CLIENT_SECRET=${API_CLIENT_SECRET}
ADMIN_CLIENT_SECRET=${ADMIN_CLIENT_SECRET}

# SMTP (Resend) - UPDATE WITH YOUR RESEND API KEY
KC_SMTP_SERVER=smtp.resend.com
KC_SMTP_PORT=587
KC_SMTP_USERNAME=resend
KC_SMTP_PASSWORD=PLACEHOLDER_RESEND_API_KEY
KC_SMTP_FROM=noreply@learn-map.in
KC_SMTP_SSL=true

# Hostname
KC_HOSTNAME=auth.learn-map.in
EOF

echo "=== Starting Keycloak ==="
docker compose --env-file .env up -d

echo "=== Waiting for Keycloak to be ready ==="
sleep 30
for i in {1..12}; do
    if curl -sf http://localhost:9000/health/ready > /dev/null 2>&1; then
        echo "Keycloak is ready!"
        break
    fi
    echo "Waiting for Keycloak... ($i/12)"
    sleep 10
done

docker compose ps

echo ""
echo "=== Deployment Complete ==="
echo "Keycloak Admin Console: https://auth.learn-map.in/admin"
echo "Admin User: admin"
echo "Admin Password: ${KC_ADMIN_PASSWORD}"
echo ""
echo "IMPORTANT: Save these credentials!"
echo "KC_ADMIN_PASSWORD=${KC_ADMIN_PASSWORD}"
echo "KC_DB_PASSWORD=${KC_DB_PASSWORD}"
echo "WEB_CLIENT_SECRET=${WEB_CLIENT_SECRET}"
echo "API_CLIENT_SECRET=${API_CLIENT_SECRET}"
echo "ADMIN_CLIENT_SECRET=${ADMIN_CLIENT_SECRET}"
echo ""
echo "Next: Add DNS A record: auth.learn-map.in -> \$(curl -s ifconfig.me)"