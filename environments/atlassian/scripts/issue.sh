#!/bin/bash
# issue.sh <KEY>  — single-issue read.
source /lib/atlassian.sh; check_auth
K="$1"; [ -n "$K" ] || { echo "usage: issue.sh <KEY>"; exit 1; }
jira_get "/rest/api/3/issue/$K?fields=summary,status,issuetype,assignee,parent,labels,updated" | jq -r '
  if .key then
    "  \(.key)  [\(.fields.issuetype.name)]  \(.fields.summary)",
    "  status:   \(.fields.status.name)",
    "  assignee: \(.fields.assignee.displayName // "unassigned")",
    "  parent:   \(.fields.parent.key // "-")",
    "  labels:   \((.fields.labels // [])|join(", "))",
    "  updated:  \(.fields.updated)",
    "  url:      https://'"$SITE"'/browse/\(.key)"
  else "  ERROR: \((.errorMessages // [.message] // ["not found"])|join("; "))" end'
