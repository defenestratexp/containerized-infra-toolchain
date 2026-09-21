#!/bin/bash
# coredns-tools container launcher

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_CLI="${AWS_CLI:-$(command -v aws || true)}"
AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-deploy}"   # ~/.aws/credentials profile
ECR_REGISTRY="${ECR_REGISTRY:-123456789012.dkr.ecr.us-west-2.amazonaws.com}"
IMAGE_NAME="homelab-coredns-tools"
ECR_IMAGE="${ECR_REGISTRY}/homelab/coredns-tools:latest"

# Default DNS server (k3s-util)
DNS_SERVER=${DNS_SERVER:-192.0.2.169}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

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

# Determine if we need interactive mode
if [ -t 0 ]; then
    DOCKER_FLAGS="-it"
else
    DOCKER_FLAGS=""
fi

info "Starting coredns-tools container (DNS: $DNS_SERVER)..."

# Build docker run command
DOCKER_CMD="docker run $DOCKER_FLAGS --rm --name coredns-tools-session"
DOCKER_CMD="$DOCKER_CMD --network host"
DOCKER_CMD="$DOCKER_CMD -e DNS_SERVER=$DNS_SERVER"
DOCKER_CMD="$DOCKER_CMD $IMAGE_NAME"

# Add any command arguments
if [ $# -gt 0 ]; then
    DOCKER_CMD="$DOCKER_CMD $*"
fi

eval $DOCKER_CMD
