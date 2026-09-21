# kubectl-k3s-public Environment

Containerized kubectl access to the k3s-public K3s cluster. Kubeconfig is fetched from AWS Secrets Manager at runtime - no credentials are baked into the image.

## Usage

```bash
# Interactive session
./run.sh

# Run single command
./run.sh get-nodes
./run.sh get-pods kube-system
./run.sh 'kubectl get deployments -A'

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
| `shell <pod> [ns]` | Exec a shell in a pod |
| `kubectl <args>` | Direct kubectl access |
| `helm <args>` | Helm package manager |
| `k9s` | Interactive cluster explorer |

## Cluster Details

| Property | Value |
|----------|-------|
| Host | k3s-public.example.internal |
| IP | 203.0.113.10 (public droplet) |
| Distribution | K3s |
| Hosting | Single-node K3s on a cloud droplet |

## Credentials

Kubeconfig is fetched from AWS Secrets Manager at container startup:
- **Secret**: `homelab/kubeconfig/k3s-public`

The `run.sh` script passes AWS credentials from the configured AWS profile (`AWS_PROFILE_NAME`, default `deploy`) to the container.

## ECR Image

```
${ECR_REGISTRY}/homelab/kubectl-k3s-public:latest
```

## Development

To build locally instead of pulling from ECR:
```bash
./run.sh --build
```
