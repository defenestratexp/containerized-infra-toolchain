#!/bin/bash
# Fetch SSH key from AWS Secrets Manager and set up Ansible
set -e

# Require AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "ERROR: AWS credentials required (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
    echo "These should be passed by run.sh from the configured AWS profile"
    exit 1
fi

export AWS_DEFAULT_REGION="${AWS_REGION:-us-west-2}"

echo "Fetching SSH key from Secrets Manager..."

# Fetch SSH key from Secrets Manager
SSH_KEY=$(aws secretsmanager get-secret-value \
    --secret-id homelab/ssh/deploy-ansible \
    --query SecretString --output text 2>/dev/null)

if [ -z "$SSH_KEY" ]; then
    echo "ERROR: Failed to fetch SSH key from homelab/ssh/deploy-ansible"
    exit 1
fi

# Write SSH key to file with correct permissions
echo "$SSH_KEY" > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

echo "SSH key loaded for Ansible"
echo ""

exec "$@"
