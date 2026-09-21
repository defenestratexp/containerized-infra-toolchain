#!/bin/bash
#
# Terraform Container Entrypoint
# Fetches Proxmox credentials from AWS Secrets Manager and handles Terraform operations
#

set -e

ACTION=${1:-plan}
ENVIRONMENT=${TF_ENVIRONMENT:-dev}
WORKSPACE=${TF_WORKSPACE:-environments}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[Terraform]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fetch Proxmox credentials from AWS Secrets Manager
fetch_credentials() {
    # Check for AWS credentials
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        error "AWS credentials required (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
        error "These should be passed by run.sh from the configured AWS profile"
        exit 1
    fi

    export AWS_DEFAULT_REGION="${AWS_REGION:-us-west-2}"

    log "Fetching Proxmox credentials from Secrets Manager..."

    # Fetch the token secret (JSON with token_id and token_secret)
    SECRET_JSON=$(aws secretsmanager get-secret-value \
        --secret-id homelab/proxmox/token \
        --query SecretString --output text 2>/dev/null)

    if [ -z "$SECRET_JSON" ]; then
        error "Failed to fetch credentials from homelab/proxmox/token"
        exit 1
    fi

    # Parse JSON and export as Terraform variables
    export TF_VAR_proxmox_api_token_id=$(echo "$SECRET_JSON" | jq -r '.token_id')
    export TF_VAR_proxmox_api_token_secret=$(echo "$SECRET_JSON" | jq -r '.token_secret')

    if [ -z "$TF_VAR_proxmox_api_token_id" ] || [ "$TF_VAR_proxmox_api_token_id" == "null" ]; then
        error "Failed to parse token_id from secret"
        exit 1
    fi

    log "Proxmox credentials loaded from Secrets Manager"
}

# Verify environment variables for Proxmox authentication
check_credentials() {
    if [ -z "$TF_VAR_proxmox_api_token_id" ] || [ -z "$TF_VAR_proxmox_api_token_secret" ]; then
        error "Missing Proxmox credentials!"
        error "Required: TF_VAR_proxmox_api_token_id and TF_VAR_proxmox_api_token_secret"
        exit 1
    fi
    log "Credentials configured"
}

# Initialize Terraform
terraform_init() {
    log "Initializing Terraform..."
    terraform init -upgrade
}

# Validate configuration
terraform_validate() {
    log "Validating Terraform configuration..."
    terraform validate
}

# Format check
terraform_fmt_check() {
    log "Checking Terraform formatting..."
    if ! terraform fmt -check -recursive; then
        warn "Terraform files are not properly formatted"
        warn "Run: terraform fmt -recursive"
        return 1
    fi
    log "Format check passed"
}

# Format files
terraform_fmt() {
    log "Formatting Terraform files..."
    terraform fmt -recursive
    log "Formatting complete"
}

# Plan changes
terraform_plan() {
    log "Planning Terraform changes..."
    terraform plan -out=/terraform-state/${ENVIRONMENT}.tfplan
    log "Plan saved to /terraform-state/${ENVIRONMENT}.tfplan"
}

# Apply changes
terraform_apply() {
    log "Applying Terraform changes..."
    if [ -f "/terraform-state/${ENVIRONMENT}.tfplan" ]; then
        terraform apply /terraform-state/${ENVIRONMENT}.tfplan
    else
        warn "No plan file found, running apply without plan"
        terraform apply -auto-approve
    fi
}

# Destroy infrastructure
terraform_destroy() {
    log "Destroying Terraform-managed infrastructure..."
    terraform destroy -auto-approve
}

# Show current state
terraform_show() {
    log "Showing Terraform state..."
    terraform show
}

# Get outputs
terraform_output() {
    log "Terraform outputs:"
    terraform output -json
}

# Main execution
main() {
    log "Terraform Container Starting"
    log "Action: $ACTION"
    log "Environment: $ENVIRONMENT"
    log "Workspace: $WORKSPACE"

    # Execute action
    case "$ACTION" in
        fmt)
            # No credentials needed for formatting
            terraform_fmt
            ;;
        fmt-check)
            # No credentials needed for format check
            terraform_fmt_check
            ;;
        init)
            fetch_credentials
            check_credentials
            terraform_init
            ;;
        validate)
            fetch_credentials
            check_credentials
            terraform_init
            terraform_validate
            ;;
        plan)
            fetch_credentials
            check_credentials
            terraform_init
            terraform_plan
            ;;
        apply)
            fetch_credentials
            check_credentials
            terraform_init
            terraform_apply
            terraform_output
            ;;
        destroy)
            fetch_credentials
            check_credentials
            terraform_init
            terraform_destroy
            ;;
        show)
            fetch_credentials
            check_credentials
            terraform_show
            ;;
        output)
            fetch_credentials
            check_credentials
            terraform_output
            ;;
        *)
            error "Unknown action: $ACTION"
            error "Valid actions: fmt, fmt-check, init, validate, plan, apply, destroy, show, output"
            exit 1
            ;;
    esac

    log "Action completed successfully"
}

main "$@"
