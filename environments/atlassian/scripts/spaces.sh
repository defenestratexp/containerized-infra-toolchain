#!/bin/bash
# spaces.sh  — list Confluence spaces (key, name, type).
source /lib/atlassian.sh; check_auth
conf_get "/rest/api/space?limit=50" | jq -r '(.results // [])[] | "  \(.key)\t\(.name)\t[\(.type)]"'
