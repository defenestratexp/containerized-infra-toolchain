#!/bin/bash
# Cloudflare tools container launcher
# Passes AWS credentials from the $AWS_PROFILE_NAME profile to container for Secrets Manager access
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_CLI="${AWS_CLI:-$(command -v aws || true)}"
AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-deploy}"   # ~/.aws/credentials profile
ECR_REGISTRY="${ECR_REGISTRY:-123456789012.dkr.ecr.us-west-2.amazonaws.com}"
IMAGE_NAME="homelab-cloudflare-tools"
ECR_IMAGE="${ECR_REGISTRY}/homelab/cloudflare-tools:latest"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

if [ ! -x "$AWS_CLI" ]; then
    error "AWS CLI not found at $AWS_CLI"
    error "Install the AWS CLI v2 or set AWS_CLI=/path/to/aws"
    exit 1
fi

if [ "$1" == "--pull" ]; then
    info "Pulling latest image from ECR..."
    $AWS_CLI ecr get-login-password --profile "$AWS_PROFILE_NAME" --region us-west-2 | \
        docker login --username AWS --password-stdin "$ECR_REGISTRY"
    docker pull "$ECR_IMAGE"
    docker tag "$ECR_IMAGE" "$IMAGE_NAME"
    shift
    success "Image updated from ECR"
fi

if [ "$1" == "--build" ]; then
    info "Building image locally..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    shift
    success "Local build complete"
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    info "Image not found locally, pulling from ECR..."
    if $AWS_CLI ecr get-login-password --profile "$AWS_PROFILE_NAME" --region us-west-2 2>/dev/null | \
        docker login --username AWS --password-stdin "$ECR_REGISTRY" 2>/dev/null && \
        docker pull "$ECR_IMAGE" 2>/dev/null; then
        docker tag "$ECR_IMAGE" "$IMAGE_NAME"
        success "Image pulled from ECR"
    else
        info "ECR pull failed, building locally..."
        docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
        success "Local build complete"
    fi
fi

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

if [ -t 0 ]; then
    DOCKER_FLAGS="-it"
else
    DOCKER_FLAGS=""
fi

info "Starting cloudflare-tools container..."

# Mount the personal repos dir so commands like cf-worker-deploy can refer
# to script files with a /repos/<repo>/... path. Set REPOS_DIR to enable.
REPOS_DIR="${REPOS_DIR:-}"

docker run $DOCKER_FLAGS --rm \
    --name cloudflare-tools \
    --network host \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_REGION=us-west-2 \
    -e CF_ACCOUNT_ID \
    -e CF_TUNNEL_NAME="${CF_TUNNEL_NAME:-homelab}" \
    -v "$SCRIPT_DIR:/workspace" \
    ${REPOS_DIR:+-v "$REPOS_DIR:/repos:ro"} \
    "$IMAGE_NAME" "$@"
