#!/bin/bash
# homelab shared container lib — baked into homelab-tools-base at /lib/common.sh.
# Logging, AWS Secrets fetch, ntfy. Written from scratch for the homelab.
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info(){ echo -e "${BLUE}INFO${NC}  $*" >&2; }
log_ok()  { echo -e "${GREEN}OK${NC}    $*" >&2; }
log_warn(){ echo -e "${YELLOW}WARN${NC}  $*" >&2; }
log_err() { echo -e "${RED}ERROR${NC} $*" >&2; }

# secrets_fetch <secret-id>  ->  SecretString (JSON) on stdout
secrets_fetch(){ aws secretsmanager get-secret-value --secret-id "$1" --query SecretString --output text 2>/dev/null; }

# ntfy_notify <topic> <message> [title]  — ntfy at $NTFY_URL (curl UA; server blocks python-urllib)
ntfy_notify(){ curl -s -H "Title: ${3:-homelab}" -d "$2" "${NTFY_URL:-https://ntfy.example.com}/${1}" >/dev/null 2>&1; }

# require <VARNAME...> — abort if any named env var is empty
require(){ local v; for v in "$@"; do [ -n "${!v}" ] || { log_err "$v not set"; exit 1; }; done; }
