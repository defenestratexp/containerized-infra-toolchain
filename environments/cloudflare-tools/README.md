# Cloudflare Tools Environment

Docker-based execution environment for Cloudflare API operations — primarily managing the `homelab` tunnel ingress (public hostnames) and DNS zones.

## Setup

Credentials come from AWS Secrets Manager (`homelab/cloudflare/api-token`) via the entrypoint. Locally you need the `~/.aws/credentials` profile named by `AWS_PROFILE_NAME` (default `deploy`) and your Cloudflare account ID in `CF_ACCOUNT_ID` (or an `account_id` key in the secret, which may be a bare token or JSON `{"token": "...", "account_id": "..."}`).

## Usage

```bash
cd environments/cloudflare-tools
export CF_ACCOUNT_ID=<your-account-id>

# Interactive shell
./run.sh

# Single command
./run.sh cf-tunnel-list
./run.sh cf-tunnel-add-hostname alerts.example.com http://192.0.2.169
./run.sh cf-tunnel-del-hostname alerts.example.com
./run.sh cf-tunnel-config | jq '.config.ingress'

# Force rebuild after Dockerfile/script changes
./run.sh --build
```

## Available commands inside the container

| Command | Purpose |
|---------|---------|
| `cf-help` | Show this list |
| `cf-tunnel-list` | Pretty-print ingress rules |
| `cf-tunnel-add-hostname <host> <service>` | Idempotently add/replace a hostname rule |
| `cf-tunnel-del-hostname <host>` | Remove a hostname rule |
| `cf-tunnel-config` | Print full tunnel config JSON |
| `cf-zone-list` | List accessible DNS zones |

## How it works

`entrypoint.sh` fetches the API token from AWS Secrets Manager, then resolves the `homelab` tunnel ID (by name, within `CF_ACCOUNT_ID`) via the API once at container startup. These are exported as `CF_ACCOUNT_ID`, `CF_TUNNEL_ID`, `CF_TUNNEL_NAME`, `CF_API_TOKEN`, and `CF_API` for the helper scripts to use.

Tunnel name can be overridden with `CF_TUNNEL_NAME=<name>` in the env passed via `run.sh`.

## Catch-all behavior

The Cloudflare tunnel ingress array's last rule must always be a service-only catch-all (no hostname; typically `service: http_status:404`). The `add-hostname` script inserts new rules before the last rule and `del-hostname` filters by hostname only, so the catch-all is preserved automatically.
