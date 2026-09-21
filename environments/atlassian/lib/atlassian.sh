#!/bin/bash
# Atlassian Cloud helpers (Jira REST v3 + Confluence). Sourced by /scripts/*.sh.
# Auth (site/email/token) comes from the entrypoint, which fetched homelab/atlassian/creds.
source /lib/common.sh 2>/dev/null || true
SITE="${ATLASSIAN_SITE}"; EMAIL="${ATLASSIAN_EMAIL}"; TOKEN="${ATLASSIAN_TOKEN}"
JIRA="https://${SITE}"; CONF="https://${SITE}/wiki"
_AUTH=(-u "${EMAIL}:${TOKEN}")
check_auth(){ require ATLASSIAN_SITE ATLASSIAN_EMAIL ATLASSIAN_TOKEN; }

jira_get(){  curl -s "${_AUTH[@]}" -H 'Accept: application/json' "${JIRA}$1"; }
jira_post(){ curl -s "${_AUTH[@]}" -H 'Accept: application/json' -H 'Content-Type: application/json' -X POST -d "$2" "${JIRA}$1"; }
jira_put(){  curl -s "${_AUTH[@]}" -H 'Accept: application/json' -H 'Content-Type: application/json' -X PUT  -d "$2" "${JIRA}$1"; }
conf_get(){  curl -s "${_AUTH[@]}" -H 'Accept: application/json' "${CONF}$1"; }
conf_post(){ curl -s "${_AUTH[@]}" -H 'Accept: application/json' -H 'Content-Type: application/json' -X POST -d "$2" "${CONF}$1"; }

# adf <text> — wrap plain text as an Atlassian Document Format doc (Jira Cloud v3 rich-text fields:
# descriptions, comments). The Cloud-vs-Server gotcha: v3 rejects plain strings for these fields.
adf(){ jq -nc --arg t "$1" '{type:"doc",version:1,content:[{type:"paragraph",content:[{type:"text",text:$t}]}]}'; }
