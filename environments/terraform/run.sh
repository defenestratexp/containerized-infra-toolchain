#!/bin/bash
# terraform container launcher
# Passes AWS credentials from the $AWS_PROFILE_NAME profile to container for Secrets Manager access

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_CLI="${AWS_CLI:-$(command -v aws || true)}"
AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-deploy}"   # ~/.aws/credentials profile
ECR_REGISTRY="${ECR_REGISTRY:-123456789012.dkr.ecr.us-west-2.amazonaws.com}"
IMAGE_NAME="homelab-terraform"
ECR_IMAGE="${ECR_REGISTRY}/homelab/terraform:latest"

# Default Terraform codebase path
TF_CODEBASE=${TF_CODEBASE:-$HOME/src/terraform-proxmox}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

usage() {
    echo "Usage: ./run.sh <action> [environment]"
    echo ""
    echo "Actions:"
    echo "  fmt           Format terraform files"
    echo "  fmt-check     Check terraform formatting"
    echo "  init          Initialize terraform"
    echo "  validate      Validate terraform configuration"
    echo "  plan          Create execution plan"
    echo "  apply         Apply changes"
    echo "  destroy       Destroy infrastructure"
    echo "  show          Show current state"
    echo "  output        Show outputs"
    echo ""
    echo "Options:"
    echo "  --pull        Pull latest image from ECR"
    echo "  --build       Build image locally"
    echo ""
    echo "Environment variables:"
    echo "  TF_CODEBASE   Path to terraform codebase (default: ~/src/terraform-proxmox)"
    echo ""
    echo "Examples:"
    echo "  ./run.sh fmt                    # Format all files"
    echo "  ./run.sh fmt-check              # Check formatting"
    echo "  ./run.sh plan dev               # Plan for dev environment"
    echo "  TF_CODEBASE=/path/to/tf ./run.sh validate"
}

# Check for AWS CLI
if [ ! -x "$AWS_CLI" ]; then
    error "AWS CLI not found at $AWS_CLI"
    error "Install the AWS CLI v2 or set AWS_CLI=/path/to/aws"
    exit 1
fi

# Handle --pull flag to fetch latest from ECR
if [ "$1" == "--pull" ]; then
    info "Pulling latest image from ECR..."
    $AWS_CLI ecr get-login-password --profile "$AWS_PROFILE_NAME" --region us-west-2 | \
        docker login --username AWS --password-stdin "$ECR_REGISTRY"
    docker pull "$ECR_IMAGE"
    docker tag "$ECR_IMAGE" "$IMAGE_NAME"
    shift
    success "Image updated from ECR"
fi

# Handle --build flag for local development
if [ "$1" == "--build" ]; then
    info "Building image locally..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    shift
    success "Local build complete"
fi

# Handle --help
if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "help" ]; then
    usage
    exit 0
fi

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    # Try to pull from ECR first
    info "Image not found locally, pulling from ECR..."
    if $AWS_CLI ecr get-login-password --profile "$AWS_PROFILE_NAME" --region us-west-2 2>/dev/null | \
        docker login --username AWS --password-stdin "$ECR_REGISTRY" 2>/dev/null && \
        docker pull "$ECR_IMAGE" 2>/dev/null; then
        docker tag "$ECR_IMAGE" "$IMAGE_NAME"
        success "Image pulled from ECR"
    else
        # Fall back to local build
        info "ECR pull failed, building locally..."
        docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
        success "Local build complete"
    fi
fi

# Get AWS credentials from the $AWS_PROFILE_NAME profile
AWS_ACCESS_KEY_ID=$($AWS_CLI configure get aws_access_key_id --profile "$AWS_PROFILE_NAME" 2>/dev/null)
AWS_SECRET_ACCESS_KEY=$($AWS_CLI configure get aws_secret_access_key --profile "$AWS_PROFILE_NAME" 2>/dev/null)
# Exported, not inlined: docker run -e VAR (no value) reads it from this
# environment, so the key never appears in the process list (ps / /proc/*/cmdline).
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    error "Could not get AWS credentials from the $AWS_PROFILE_NAME profile"
    error "Ensure ~/.aws/credentials has a [$AWS_PROFILE_NAME] section"
    exit 1
fi

# Parse arguments
ACTION=${1:-fmt-check}
ENVIRONMENT=${2:-}

# Verify codebase exists
if [ ! -d "$TF_CODEBASE" ]; then
    error "Terraform codebase not found: $TF_CODEBASE"
    error "Set TF_CODEBASE environment variable to your terraform repo path"
    exit 1
fi

# Determine working directory
if [ -n "$ENVIRONMENT" ]; then
    WORKDIR="$TF_CODEBASE/environments/$ENVIRONMENT"
    if [ ! -d "$WORKDIR" ]; then
        error "Environment directory not found: $WORKDIR"
        exit 1
    fi
else
    WORKDIR="$TF_CODEBASE"
fi

info "Action: $ACTION"
info "Codebase: $TF_CODEBASE"
[ -n "$ENVIRONMENT" ] && info "Environment: $ENVIRONMENT"

# Determine if we need interactive mode
if [ -t 0 ]; then
    DOCKER_FLAGS="-it"
else
    DOCKER_FLAGS=""
fi

# Create state directory if it doesn't exist
STATE_DIR="$SCRIPT_DIR/state"
mkdir -p "$STATE_DIR"

# Build docker run command
docker run $DOCKER_FLAGS --rm --name terraform-session \
    --network host \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_REGION=us-west-2 \
    -e TF_ENVIRONMENT="$ENVIRONMENT" \
    -v "$TF_CODEBASE":/workspace \
    -v "$STATE_DIR":/terraform-state \
    -w "/workspace${ENVIRONMENT:+/environments/$ENVIRONMENT}" \
    "$IMAGE_NAME" "$ACTION"
