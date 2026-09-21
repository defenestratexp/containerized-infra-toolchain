#!/bin/bash
# transitions.sh <KEY>  — list available transitions (id, name, target status).
source /lib/atlassian.sh; check_auth
K="$1"; [ -n "$K" ] || { echo "usage: transitions.sh <KEY>"; exit 1; }
jira_get "/rest/api/3/issue/$K/transitions" | jq -r '.transitions[]? | "  \(.id)  \(.name)  -> \(.to.name)"'
