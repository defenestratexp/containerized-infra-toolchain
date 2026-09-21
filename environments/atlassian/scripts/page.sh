#!/bin/bash
# page.sh get <PAGE_ID>
# page.sh create <SPACE_KEY> "<TITLE>" "<HTML>" [PARENT_ID]   — HTML is Confluence storage format.
source /lib/atlassian.sh; check_auth
CMD="$1"
case "$CMD" in
  get)
    ID="$2"; [ -n "$ID" ] || { echo "usage: page.sh get <id>"; exit 1; }
    conf_get "/rest/api/content/$ID?expand=version,space" | jq -r 'if .id then "  \(.id)  \(.title)  (space \(.space.key), v\(.version.number))  https://'"$SITE"'/wiki/spaces/\(.space.key)/pages/\(.id)" else "  ERROR: \(.message // "not found")" end';;
  create)
    SP="$2"; TITLE="$3"; HTML="$4"; PARENT="$5"
    [ -n "$SP" ] && [ -n "$TITLE" ] || { echo "usage: page.sh create <SPACE_KEY> \"<title>\" \"<html>\" [parent_id]"; exit 1; }
    BODY=$(jq -nc --arg sp "$SP" --arg t "$TITLE" --arg h "$HTML" '{type:"page",title:$t,space:{key:$sp},body:{storage:{value:$h,representation:"storage"}}}')
    [ -n "$PARENT" ] && BODY=$(echo "$BODY" | jq -c --arg p "$PARENT" '.ancestors=[{id:$p}]')
    RESP=$(conf_post "/rest/api/content" "$BODY")
    ID=$(echo "$RESP" | jq -r '.id // empty')
    [ -n "$ID" ] && echo "created page $ID   https://$SITE/wiki/spaces/$SP/pages/$ID" \
      || { echo "ERROR: $(echo "$RESP" | jq -c '.message // .')"; exit 1; };;
  *) echo "usage: page.sh get <id> | page.sh create <space> \"<title>\" \"<html>\" [parent]";;
esac
