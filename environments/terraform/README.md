# terraform Environment

Containerized Terraform execution for Proxmox infrastructure management. Proxmox API credentials are fetched from AWS Secrets Manager at runtime - no credentials are baked into the image.

## Usage

```bash
# Check formatting (default)
./run.sh

# Format terraform files
./run.sh fmt

# Check formatting
./run.sh fmt-check

# Plan changes for specific environment
./run.sh plan dev

# Apply changes
./run.sh apply dev

# Pull latest from ECR
./run.sh --pull

# Build locally (development)
./run.sh --build
```

## Available Actions

| Action | Description |
|--------|-------------|
| `fmt` | Format terraform files |
| `fmt-check` | Check terraform formatting |
| `init` | Initialize terraform |
| `validate` | Validate terraform configuration |
| `plan` | Create execution plan |
| `apply` | Apply changes |
| `destroy` | Destroy infrastructure |
| `show` | Show current state |
| `output` | Show outputs |

## Configuration

- **Codebase**: Set `TF_CODEBASE` to your terraform repo (default: `~/src/terraform-proxmox`)
- **State**: Plan files stored in `./state/` directory
- **Network**: Host network for Proxmox API access

## Credentials

Proxmox API credentials are fetched from AWS Secrets Manager at container startup:
- **Secret**: `homelab/proxmox/token`
- **Format**: JSON with `token_id` and `token_secret` fields

The `run.sh` script passes AWS credentials from the configured AWS profile (`AWS_PROFILE_NAME`, default `deploy`) to the container.

## Example Workflows

### Format and Validate
```bash
./run.sh fmt
./run.sh validate dev
```

### Plan and Apply
```bash
./run.sh plan dev
# Review plan output
./run.sh apply dev
```

### Custom Codebase
```bash
TF_CODEBASE=/path/to/other/terraform ./run.sh plan dev
```

## ECR Image

```
${ECR_REGISTRY}/homelab/terraform:latest
```

## Development

To build locally instead of pulling from ECR:
```bash
./run.sh --build
```

## Notes

- Formatting actions (`fmt`, `fmt-check`) do not require Proxmox credentials
- All other actions fetch credentials from Secrets Manager
- State files are saved to `./state/${ENVIRONMENT}.tfplan`
