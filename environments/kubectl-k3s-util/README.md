# kubectl-k3s-util Environment

Containerized kubectl access to the k3s-util K3s cluster. Kubeconfig is fetched from AWS Secrets Manager at runtime - no credentials are baked into the image.

## Usage

```bash
# Interactive session
./run.sh

# Run single command
./run.sh get-nodes
./run.sh get-pods kube-system
./run.sh 'kubectl get deployments --all-namespaces'

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
| Host | k3s-util.example.internal |
| IP | 192.0.2.169 |
| Distribution | K3s |
| Primary Namespace | kube-system |

## Key Services

- CoreDNS (internal DNS resolution)
- Jenkins-related K8s services
- Infrastructure utilities

## Credentials

Kubeconfig is fetched from AWS Secrets Manager at container startup:
- **Secret**: `homelab/kubeconfig/k3s-util`

The `run.sh` script passes AWS credentials from the configured AWS profile (`AWS_PROFILE_NAME`, default `deploy`) to the container.

## ECR Image

```
${ECR_REGISTRY}/homelab/kubectl-k3s-util:latest
```

## Development

To build locally instead of pulling from ECR:
```bash
./run.sh --build
```
