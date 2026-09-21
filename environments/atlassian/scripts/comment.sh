#!/bin/bash
# comment.sh <KEY> "<TEXT>"   — add a comment (wrapped as ADF for Cloud v3).
source /lib/atlassian.sh; check_auth
K="$1"; T="$2"; [ -n "$K" ] && [ -n "$T" ] || { echo "usage: comment.sh <KEY> \"<text>\""; exit 1; }
RESP=$(jira_post "/rest/api/3/issue/$K/comment" "$(jq -nc --argjson b "$(adf "$T")" '{body:$b}')")
echo "$RESP" | jq -e '.id' >/dev/null 2>&1 && echo "commented on $K" \
  || { echo "ERROR: $(echo "$RESP" | jq -c '.errors // .errorMessages // .')"; exit 1; }
