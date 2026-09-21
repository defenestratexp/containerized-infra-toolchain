#!/bin/bash
# Fetch Proxmox credentials from AWS Secrets Manager
set -e

# Require AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "ERROR: AWS credentials required (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
    echo "These should be passed by run.sh from the configured AWS profile"
    exit 1
fi

export AWS_DEFAULT_REGION="${AWS_REGION:-us-west-2}"

echo "Fetching Proxmox credentials from Secrets Manager..."

# Fetch credentials from Secrets Manager
PROXMOX_CREDS=$(aws secretsmanager get-secret-value \
    --secret-id homelab/proxmox/token \
    --query SecretString --output text 2>/dev/null)

if [ -z "$PROXMOX_CREDS" ]; then
    echo "ERROR: Failed to fetch credentials from homelab/proxmox/token"
    exit 1
fi

# Export Proxmox environment variables
export PROXMOX_HOST="${PROXMOX_HOST:-pve1}"
export PROXMOX_USER=$(echo "$PROXMOX_CREDS" | jq -r '.api_user // "deploy@pam"')
export PROXMOX_TOKEN_NAME="deploy_token"
export PROXMOX_TOKEN_VALUE=$(echo "$PROXMOX_CREDS" | jq -r '.deploy_token')

echo "Proxmox credentials loaded"
echo "  Host: $PROXMOX_HOST"
echo "  User: $PROXMOX_USER"
echo ""

exec "$@"
