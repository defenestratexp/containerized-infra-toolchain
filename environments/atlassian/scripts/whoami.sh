#!/bin/bash
# Identity / auth probe for both products.
source /lib/atlassian.sh
check_auth
echo "site: $SITE    user: $EMAIL"
echo "== Jira =="
jira_get /rest/api/3/myself | jq -r 'if .accountId then "  " + .displayName + "  accountId=" + .accountId else "  ERROR: " + (.message // (.errorMessages|join("; ")) // "auth failed") end'
echo "== Confluence =="
conf_get "/rest/api/space?limit=1" | jq -r 'if has("results") then "  reachable — " + ((.size // (.results|length))|tostring) + " space(s) visible" else "  ERROR: " + (.message // "unexpected response") end'
