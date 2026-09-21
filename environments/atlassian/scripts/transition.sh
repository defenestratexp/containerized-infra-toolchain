#!/bin/bash
# transition.sh <KEY> "<transition or target-status name>"  — case-insensitive match.
source /lib/atlassian.sh; check_auth
K="$1"; NAME="$2"; [ -n "$K" ] && [ -n "$NAME" ] || { echo "usage: transition.sh <KEY> \"<name>\""; exit 1; }
TRS=$(jira_get "/rest/api/3/issue/$K/transitions")
ID=$(echo "$TRS" | jq -r --arg n "$NAME" '.transitions[] | select((.name|ascii_downcase)==($n|ascii_downcase) or (.to.name|ascii_downcase)==($n|ascii_downcase)) | .id' | head -1)
[ -n "$ID" ] || { echo "no transition matching '$NAME'. options:"; echo "$TRS" | jq -r '.transitions[] | "  "+.name+" -> "+.to.name'; exit 1; }
RESP=$(jira_post "/rest/api/3/issue/$K/transitions" "$(jq -nc --arg id "$ID" '{transition:{id:$id}}')")
[ -z "$RESP" ] && echo "transitioned $K -> $NAME" \
  || echo "ERROR: $(echo "$RESP" | jq -c '.errors // .errorMessages // .')"
