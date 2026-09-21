# Terraform Execution Container
# Proxmox credentials fetched from AWS Secrets Manager at runtime via entrypoint.sh
FROM hashicorp/terraform:1.9

LABEL maintainer="homelab"
LABEL description="Terraform execution environment for Proxmox infrastructure"

# Install additional tools including aws-cli for secrets management
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    openssh-client \
    ca-certificates \
    aws-cli

# Create working directory
WORKDIR /workspace

# Copy helper scripts
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["plan"]
