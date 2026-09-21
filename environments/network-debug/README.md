# network-debug Environment

Comprehensive network troubleshooting toolkit. No credentials required - runs with NET_RAW and NET_ADMIN capabilities for full network access.

## Usage

```bash
# Interactive session
./run.sh

# Run specific commands
./run.sh port-check 192.0.2.68 22 80 443 6443
./run.sh latency-test
./run.sh 'nmap -F 192.0.2.68'

# Pull latest from ECR
./run.sh --pull

# Build locally (development)
./run.sh --build
```

## Available Commands

Inside the container:

| Command | Description |
|---------|-------------|
| `port-check <host> [ports]` | Check if ports are open |
| `http-check <url>` | Test HTTP/HTTPS endpoint |
| `network-scan <target> [type]` | Scan network (quick/ports/full/services) |
| `latency-test [hosts]` | Test latency with ping and mtr |
| `host-info <host>` | Comprehensive host information |

### Raw Tools

| Tool | Description |
|------|-------------|
| `nmap` | Network scanner |
| `tcpdump` | Packet capture |
| `tshark` | Wireshark CLI |
| `mtr` | Traceroute + ping |
| `iperf3` | Bandwidth testing |
| `nc` | Netcat |
| `socat` | Socket relay |
| `curl` / `wget` | HTTP clients |
| `dig` / `nslookup` | DNS tools |
| `traceroute` | Route tracing |
| `ss` / `netstat` | Socket statistics |

## Example Workflows

### Check Service Availability
```bash
./run.sh port-check 192.0.2.68 22 80 443 6443
```

### Test API Endpoint
```bash
./run.sh http-check http://192.0.2.68:8080/healthz
```

### Scan Network Subnet
```bash
./run.sh network-scan 192.0.2.0/24 quick
```

### Test Latency to Infrastructure
```bash
./run.sh latency-test "192.0.2.68 192.0.2.169"
```

### Capture Packets
```bash
./run.sh 'tcpdump -i any port 53 -c 20'
```

### Bandwidth Test
```bash
# On server: iperf3 -s
# On client:
./run.sh 'iperf3 -c 192.0.2.68'
```

## ECR Image

```
${ECR_REGISTRY}/homelab/network-debug:latest
```

## Notes

- Runs with `--cap-add NET_RAW NET_ADMIN` for raw socket access
- Uses host network for accurate network testing
- Some scans (full port scan, packet capture) may need additional permissions
