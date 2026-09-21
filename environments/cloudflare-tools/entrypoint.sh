#!/bin/bash
# Cloudflare tools entrypoint - fetches API token from AWS Secrets Manager
# and resolves account_id + tunnel_id for the homelab tunnel once at startup.
set -e

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "ERROR: AWS credentials required (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
    echo "These should be passed by run.sh from the configured AWS profile"
    exit 1
fi

export AWS_DEFAULT_REGION="${AWS_REGION:-us-west-2}"

echo "Fetching Cloudflare API token from Secrets Manager..."
CF_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id homelab/cloudflare/api-token \
    --query SecretString \
    --output text 2>/dev/null) || {
    echo "ERROR: Failed to fetch homelab/cloudflare/api-token"
    exit 1
}

# Secret may be a bare token or JSON {"token": "..."}; handle both.
if echo "$CF_SECRET" | jq -e '.token' >/dev/null 2>&1; then
    export CF_API_TOKEN=$(echo "$CF_SECRET" | jq -r '.token')
else
    export CF_API_TOKEN="$CF_SECRET"
fi

if [ -z "$CF_API_TOKEN" ] || [ "$CF_API_TOKEN" = "null" ]; then
    echo "ERROR: Cloudflare token empty"
    exit 1
fi

CF_API="https://api.cloudflare.com/client/v4"
TUNNEL_NAME="${CF_TUNNEL_NAME:-homelab}"

# Account ID must be supplied (single-tenant tooling). A scoped API token without
# Account:Read permission can't list /accounts, so discovery isn't reliable.
# Pass CF_ACCOUNT_ID through run.sh (or store it in the secret as "account_id").
if [ -z "$CF_ACCOUNT_ID" ] && echo "$CF_SECRET" | jq -e '.account_id' >/dev/null 2>&1; then
    CF_ACCOUNT_ID=$(echo "$CF_SECRET" | jq -r '.account_id')
fi
if [ -z "$CF_ACCOUNT_ID" ]; then
    echo "ERROR: CF_ACCOUNT_ID not set (export it before ./run.sh, or add account_id to the secret)"
    exit 1
fi
export CF_ACCOUNT_ID

# Resolve tunnel ID by name.
TUNNELS=$(curl -4 -fsS -H "Authorization: Bearer $CF_API_TOKEN" \
    "$CF_API/accounts/$CF_ACCOUNT_ID/cfd_tunnel?name=$TUNNEL_NAME&is_deleted=false")
export CF_TUNNEL_ID=$(echo "$TUNNELS" | jq -r '.result[0].id')
export CF_TUNNEL_NAME

if [ -z "$CF_TUNNEL_ID" ] || [ "$CF_TUNNEL_ID" = "null" ]; then
    echo "ERROR: Tunnel '$TUNNEL_NAME' not found in account $CF_ACCOUNT_ID"
    exit 1
fi

export CF_API

echo "Cloudflare context loaded:"
echo "  Account:  $CF_ACCOUNT_ID"
echo "  Tunnel:   $TUNNEL_NAME ($CF_TUNNEL_ID)"
echo ""

exec "$@"
