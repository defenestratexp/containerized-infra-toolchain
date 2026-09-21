#!/bin/bash
# search.sh "<JQL>" [MAX]   — arbitrary JQL via the current endpoint.
# (GET /rest/api/3/search was removed 2024/25 → CHANGE-2046; use POST /rest/api/3/search/jql.)
source /lib/atlassian.sh; check_auth
JQL="$1"; MAX="${2:-25}"; [ -n "$JQL" ] || { echo "usage: search.sh \"<jql>\" [max]"; exit 1; }
BODY=$(jq -nc --arg jql "$JQL" --argjson max "$MAX" \
  '{jql:$jql, maxResults:$max, fields:["summary","status","issuetype","parent"]}')
jira_post "/rest/api/3/search/jql" "$BODY" | jq -r '
  if .issues then (.issues[] | "  \(.key)  [\(.fields.issuetype.name)]  \(.fields.status.name)  \(.fields.summary)\(if .fields.parent then "  (^\(.fields.parent.key))" else "" end)")
  else "  ERROR: \((.errorMessages // [.message] // ["error"])|join("; "))" end'
