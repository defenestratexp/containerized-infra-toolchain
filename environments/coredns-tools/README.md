# coredns-tools Environment

DNS debugging and management tools for CoreDNS on k3s-util. No credentials required - just network access.

## Usage

```bash
# Interactive session
./run.sh

# Run specific commands
./run.sh dns-check
./run.sh dns-query k3s-main.example.internal
./run.sh 'dig @192.0.2.169 nas.example.internal'

# Use different DNS server
DNS_SERVER=8.8.8.8 ./run.sh dns-query google.com

# Pull latest from ECR
./run.sh --pull

# Build locally (development)
./run.sh --build
```

## Available Commands

Inside the container:

| Command | Description |
|---------|-------------|
| `dns-query <host> [type]` | Query DNS record (A, AAAA, MX, etc.) |
| `dns-check` | Health check a list of internal hosts (`DNS_CHECK_HOSTS`) |
| `dns-trace <host>` | Trace DNS resolution path |
| `list-records <domain>` | List records for a domain |
| `dig` | Full dig utility |
| `drill` | DNSSEC-aware DNS lookup |
| `whois` | Domain registration lookup |

## Configuration

- **DNS_SERVER**: Target DNS server (default: 192.0.2.169 / k3s-util)
- **Network**: Host network for DNS access

## Example Workflows

### Check Internal DNS Health
```bash
./run.sh dns-check
```

### Query Specific Record
```bash
./run.sh dns-query media.example.internal A
./run.sh dns-query example.internal MX
```

### Debug Resolution Issues
```bash
./run.sh dns-trace problematic-host.example.internal
```

### Compare DNS Servers
```bash
DNS_SERVER=192.0.2.169 ./run.sh dns-query k3s-main.example.internal
DNS_SERVER=8.8.8.8 ./run.sh dns-query google.com
```

## ECR Image

```
${ECR_REGISTRY}/homelab/coredns-tools:latest
```

## Included Tools

- **bind-tools**: dig, nslookup, host
- **drill**: DNSSEC-aware lookups
- **ldns**: DNS library tools
- **whois**: Domain registration info
- **tcpdump**: Packet capture for DNS debugging
- **netcat**: Network connectivity testing
