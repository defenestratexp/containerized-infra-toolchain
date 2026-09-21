# Proxmox Environment

Containerized Proxmox API tooling. Credentials are fetched from AWS Secrets Manager at runtime - no secrets are baked into the image.

## Usage

```bash
# Interactive session
./run.sh

# Run pxm commands
./run.sh vm list
./run.sh node list
./run.sh vm status 100

# Target different Proxmox host
PROXMOX_HOST=pve2 ./run.sh vm list

# Pull latest from ECR
./run.sh --pull

# Build locally (development)
./run.sh --build
```

## Available Commands

### VM Operations
| Command | Description |
|---------|-------------|
| `vm list` | List all VMs |
| `vm get <vmid>` | Get VM details |
| `vm start <vmid>` | Start VM |
| `vm stop <vmid>` | Stop VM (use --force to force) |
| `vm shutdown <vmid>` | Graceful shutdown |
| `vm restart <vmid>` | Restart VM |
| `vm status <vmid>` | Check VM status |
| `vm config <vmid>` | Show VM config |
| `vm clone <src> <dest>` | Clone VM |
| `vm delete <vmid>` | Delete VM |

### Node Operations
| Command | Description |
|---------|-------------|
| `node list` | List all nodes |
| `node status <node>` | Node status and resources |
| `node tasks <node>` | Recent tasks |
| `node network <node>` | Network configuration |

### Storage Operations
| Command | Description |
|---------|-------------|
| `storage list` | List storage pools |
| `storage status <pool>` | Storage status |
| `storage content <pool>` | View content |

### Snapshot Operations
| Command | Description |
|---------|-------------|
| `snapshot list <vmid>` | List snapshots |
| `snapshot create <vmid> <name>` | Create snapshot |
| `snapshot delete <vmid> <name>` | Delete snapshot |
| `snapshot rollback <vmid> <name>` | Rollback to snapshot |

## Target Hosts

| Host | Description |
|------|-------------|
| pve1 | Primary Proxmox host (default) |
| pve2 | Secondary Proxmox host |

## Credentials

Credentials are fetched from AWS Secrets Manager at container startup:
- **Secret**: `homelab/proxmox/token`
- **Keys used**: `api_user`, `deploy_token`

The `run.sh` script passes AWS credentials from the configured AWS profile (`AWS_PROFILE_NAME`, default `deploy`) to the container.

## ECR Image

```
${ECR_REGISTRY}/homelab/proxmox:latest
```

## Development

To build locally instead of pulling from ECR:
```bash
./run.sh --build
```
