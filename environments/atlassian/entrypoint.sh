#!/bin/bash
# Fetch Atlassian creds from AWS Secrets Manager at runtime — never baked into the image.
set -e
SECRET="${ATLASSIAN_SECRET:-homelab/atlassian/creds}"
CREDS=$(aws secretsmanager get-secret-value --secret-id "$SECRET" --query SecretString --output text 2>/dev/null)
if [ -z "$CREDS" ]; then
    echo "ERROR: could not fetch $SECRET from AWS Secrets Manager (check AWS creds)" >&2
    exit 1
fi
export ATLASSIAN_SITE=$(echo "$CREDS"  | jq -r '.site')
export ATLASSIAN_EMAIL=$(echo "$CREDS" | jq -r '.email')
export ATLASSIAN_TOKEN=$(echo "$CREDS" | jq -r '.token')
exec "$@"
