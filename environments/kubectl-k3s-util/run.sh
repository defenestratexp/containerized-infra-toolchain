#!/bin/bash
# kubectl-k3s-util container launcher
# Passes AWS credentials from the $AWS_PROFILE_NAME profile to container for Secrets Manager access

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_CLI="${AWS_CLI:-$(command -v aws || true)}"
AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-deploy}"   # ~/.aws/credentials profile
ECR_REGISTRY="${ECR_REGISTRY:-123456789012.dkr.ecr.us-west-2.amazonaws.com}"
IMAGE_NAME="homelab-kubectl-k3s-util"
ECR_IMAGE="${ECR_REGISTRY}/homelab/kubectl-k3s-util:latest"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

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

# Determine if we need interactive mode
if [ -t 0 ]; then
    DOCKER_FLAGS="-it"
else
    DOCKER_FLAGS=""
fi

info "Starting kubectl-k3s-util container..."

# Build docker run command
DOCKER_CMD="docker run $DOCKER_FLAGS --rm --name kubectl-k3s-util-session"
DOCKER_CMD="$DOCKER_CMD --network host"
DOCKER_CMD="$DOCKER_CMD -e AWS_ACCESS_KEY_ID"
DOCKER_CMD="$DOCKER_CMD -e AWS_SECRET_ACCESS_KEY"
DOCKER_CMD="$DOCKER_CMD -e AWS_REGION=us-west-2"

# Mount manifests directory if it exists
MANIFESTS_DIR="${MANIFESTS_DIR:-}"   # optional: host dir of manifests, mounted read-only at /manifests
if [ -n "$MANIFESTS_DIR" ] && [ -d "$MANIFESTS_DIR" ]; then
    DOCKER_CMD="$DOCKER_CMD -v $MANIFESTS_DIR:/manifests:ro"
fi

# Mount workspace
DOCKER_CMD="$DOCKER_CMD -v $SCRIPT_DIR:/workspace"

DOCKER_CMD="$DOCKER_CMD $IMAGE_NAME"

# Add any command arguments
if [ $# -gt 0 ]; then
    DOCKER_CMD="$DOCKER_CMD $*"
fi

eval $DOCKER_CMD
