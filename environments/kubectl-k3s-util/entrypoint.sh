#!/bin/bash
# Fetch kubeconfig from AWS Secrets Manager and set up kubectl
set -e

# Require AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "ERROR: AWS credentials required (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
    echo "These should be passed by run.sh from the configured AWS profile"
    exit 1
fi

export AWS_DEFAULT_REGION="${AWS_REGION:-us-west-2}"

echo "Fetching kubeconfig from Secrets Manager..."

# Fetch kubeconfig from Secrets Manager
KUBECONFIG_CONTENT=$(aws secretsmanager get-secret-value \
    --secret-id homelab/kubeconfig/k3s-util \
    --query SecretString --output text 2>/dev/null)

if [ -z "$KUBECONFIG_CONTENT" ]; then
    echo "ERROR: Failed to fetch kubeconfig from homelab/kubeconfig/k3s-util"
    exit 1
fi

# Write kubeconfig to file
echo "$KUBECONFIG_CONTENT" > /root/.kube/config
chmod 600 /root/.kube/config

echo "Kubeconfig loaded for k3s-util cluster"

# Test cluster connectivity
echo ""
echo "Testing cluster connectivity..."
if kubectl cluster-info >/dev/null 2>&1; then
    echo "Successfully connected to k3s-util cluster"
    echo ""
    kubectl get nodes
else
    echo "WARNING: Cannot connect to k3s-util cluster"
    echo "Check network connectivity to 192.0.2.169:6443"
fi

echo ""
exec "$@"
