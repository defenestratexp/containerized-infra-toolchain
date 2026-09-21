#!/bin/bash
# Atlassian env runner. Builds homelab-tools-base + homelab-atlassian on first use, passes AWS
# creds from the configured profile, and (via entrypoint) fetches homelab/atlassian/creds at
# runtime — the Atlassian token never touches the host CLI.
#
# Usage:
#   ./run.sh /scripts/whoami.sh
#   ./run.sh /scripts/create.sh Task "Summary" "Description" [PARENT_KEY]
#   ./run.sh                                        (interactive shell)
#   ./run.sh --build ...                            (force rebuild of both images)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_CLI="${AWS_CLI:-$(command -v aws || true)}"
AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-deploy}"   # ~/.aws/credentials profile

if [ "$1" == "--build" ]; then FORCE_BUILD=1; shift; fi

if [ -n "$FORCE_BUILD" ] || ! docker image inspect homelab-tools-base >/dev/null 2>&1; then
    docker build -t homelab-tools-base -f "$SCRIPT_DIR/../_shared/Dockerfile.base" "$SCRIPT_DIR/../_shared"
fi
if [ -n "$FORCE_BUILD" ] || ! docker image inspect homelab-atlassian >/dev/null 2>&1; then
    docker build -t homelab-atlassian "$SCRIPT_DIR"
fi

AWS_ACCESS_KEY_ID=$("$AWS_CLI" configure get aws_access_key_id --profile "$AWS_PROFILE_NAME" 2>/dev/null)
AWS_SECRET_ACCESS_KEY=$("$AWS_CLI" configure get aws_secret_access_key --profile "$AWS_PROFILE_NAME" 2>/dev/null)
[ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ] || { echo "ERROR: could not read AWS creds for profile $AWS_PROFILE_NAME" >&2; exit 1; }
# Exported, not inlined: docker run -e VAR (no value) reads it from this
# environment, so the key never appears in the process list (ps / /proc/*/cmdline).
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

FLAGS=""; [ -t 0 ] && FLAGS="-it"
exec docker run --rm $FLAGS --network host \
    -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_REGION="${AWS_REGION:-us-west-2}" \
    -e JIRA_PROJECT \
    -v "$SCRIPT_DIR/scripts:/scripts:ro" \
    homelab-atlassian "$@"
