# kubectl-k3s-main Environment

Containerized kubectl access to the k3s-main K3s cluster. Kubeconfig is fetched from AWS Secrets Manager at runtime - no credentials are baked into the image.

## Usage

```bash
# Interactive session
./run.sh

# Run single command
./run.sh get-nodes
./run.sh get-pods media
./run.sh 'kubectl get deployments -n media'

# Pull latest from ECR
./run.sh --pull

# Build locally (development)
./run.sh --build
```

## Available Commands

| Command | Description |
|---------|-------------|
| `get-nodes` | Show cluster nodes |
| `get-pods [namespace]` | Show pods (all namespaces if none specified) |
| `get-services [namespace]` | Show services |
| `cluster-info` | Show cluster overview |
| `deploy-manifest <file> [ns]` | Deploy K8s manifest |
| `watch-pods [namespace]` | Watch pods in real-time |
| `logs <pod> [ns] [container]` | Get pod logs |
| `kubectl <args>` | Direct kubectl access |
| `helm <args>` | Helm package manager |
| `k9s` | Interactive cluster explorer |

## Cluster Details

| Property | Value |
|----------|-------|
| Host | k3s-main.example.internal |
| IP | 192.0.2.68 |
| Distribution | K3s |
| Primary Namespace | media |

## Credentials

Kubeconfig is fetched from AWS Secrets Manager at container startup:
- **Secret**: `homelab/kubeconfig/k3s-main`

The `run.sh` script passes AWS credentials from the configured AWS profile (`AWS_PROFILE_NAME`, default `deploy`) to the container.

## ECR Image

```
${ECR_REGISTRY}/homelab/kubectl-k3s-main:latest
```

## Development

To build locally instead of pulling from ECR:
```bash
./run.sh --build
```
