#!/bin/bash
# worklog.sh <KEY> <TIME> ["COMMENT"]   TIME like 30m, 1h, 2h30m, 1d
source /lib/atlassian.sh; check_auth
K="$1"; T="$2"; C="$3"; [ -n "$K" ] && [ -n "$T" ] || { echo "usage: worklog.sh <KEY> <time> [\"comment\"]"; exit 1; }
BODY=$(jq -nc --arg t "$T" '{timeSpent:$t}')
[ -n "$C" ] && BODY=$(echo "$BODY" | jq -c --argjson c "$(adf "$C")" '.comment=$c')
RESP=$(jira_post "/rest/api/3/issue/$K/worklog" "$BODY")
echo "$RESP" | jq -e '.id' >/dev/null 2>&1 && echo "logged $T on $K" \
  || { echo "ERROR: $(echo "$RESP" | jq -c '.errors // .errorMessages // .')"; exit 1; }
