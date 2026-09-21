# ansible-local Environment

Containerized Ansible execution for local playbook testing and development. SSH key is fetched from AWS Secrets Manager at runtime - no credentials are baked into the image.

## Usage

```bash
# Interactive session
./run.sh

# Run specific commands
./run.sh run-playbook playbooks/ping_check.yml
./run.sh ping-all
./run.sh list-playbooks

# Pull latest from ECR
./run.sh --pull

# Build locally (development)
./run.sh --build
```

## Available Commands

Inside the container:

| Command | Description |
|---------|-------------|
| `run-playbook <playbook>` | Execute a playbook |
| `list-playbooks` | List available playbooks |
| `ping-all` | Test connectivity to all hosts |
| `run-command <group> "<cmd>"` | Run ad-hoc command |
| `ansible-playbook` | Direct Ansible CLI |

## Configuration

- **Repository**: `/workspace` (mounted read-only from `$ANSIBLE_REPO_PATH`)
- **SSH Key**: Fetched from AWS Secrets Manager at runtime
- **Network**: Host network for DNS resolution
- **Inventory**: `inventory/hosts` (relative to workspace)

## Credentials

SSH key is fetched from AWS Secrets Manager at container startup:
- **Secret**: `homelab/ssh/deploy-ansible`

The `run.sh` script passes AWS credentials from the configured AWS profile (`AWS_PROFILE_NAME`, default `deploy`) to the container.

## When to Use

| Scenario | Use |
|----------|-----|
| Production deployment | Jenkins |
| Quick playbook test | ansible-local |
| Playbook development | ansible-local |
| Debugging | ansible-local |
| Tracked execution | Jenkins |

## Example Workflows

### Run a Playbook
```bash
./run.sh
run-playbook playbooks/ping_check.yml
```

### Test Connectivity
```bash
./run.sh ping-all
```

### Target Specific Hosts
```bash
./run.sh 'ansible-playbook -i inventory/hosts playbooks/fluxbox.yml -l workstation'
```

## ECR Image

```
${ECR_REGISTRY}/homelab/ansible-local:latest
```

## Development

To build locally instead of pulling from ECR:
```bash
./run.sh --build
```
