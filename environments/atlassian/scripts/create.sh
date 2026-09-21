#!/bin/bash
# create.sh <TYPE> "<SUMMARY>" ["DESCRIPTION"] [PARENT_KEY]
#   TYPE:  Epic | Story | Task | Bug | Subtask | Feature
#   PARENT_KEY: an Epic key (for a Story/Task under it) or a Task/Story key (for a Subtask). Team-managed
#               projects use the single `parent` field for both.
#   Project defaults to $JIRA_PROJECT or KAN. Self-assigns to the token account.
source /lib/atlassian.sh; check_auth
TYPE="$1"; SUMMARY="$2"; DESC="$3"; PARENT="$4"
PROJECT="${JIRA_PROJECT:-KAN}"
[ -n "$TYPE" ] && [ -n "$SUMMARY" ] || { echo "usage: create.sh <TYPE> \"<SUMMARY>\" [\"DESC\"] [PARENT_KEY]"; exit 1; }
ME=$(jira_get /rest/api/3/myself | jq -r '.accountId')
FIELDS=$(jq -nc --arg p "$PROJECT" --arg t "$TYPE" --arg s "$SUMMARY" --arg me "$ME" \
  '{fields:{project:{key:$p},issuetype:{name:$t},summary:$s,assignee:{accountId:$me}}}')
[ -n "$DESC" ]   && FIELDS=$(echo "$FIELDS" | jq -c --argjson d "$(adf "$DESC")" '.fields.description=$d')
[ -n "$PARENT" ] && FIELDS=$(echo "$FIELDS" | jq -c --arg pk "$PARENT" '.fields.parent={key:$pk}')
RESP=$(jira_post /rest/api/3/issue "$FIELDS")
KEY=$(echo "$RESP" | jq -r '.key // empty')
if [ -n "$KEY" ]; then echo "created $KEY   https://$SITE/browse/$KEY"
else echo "ERROR: $(echo "$RESP" | jq -c '.errors // .errorMessages // .')"; exit 1; fi
