# Proxmox API Tooling Container
# Credentials fetched from AWS Secrets Manager at runtime via entrypoint.sh
FROM python:3.11-slim

LABEL maintainer="homelab"
LABEL description="Proxmox API tooling with CLI wrappers - no baked credentials"

# Install system dependencies including AWS CLI
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    jq \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Set working directory
WORKDIR /opt/proxmox-api

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy scripts and library
COPY scripts/ /opt/proxmox-api/scripts/

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /opt/proxmox-api/scripts/pxm /entrypoint.sh && \
    ln -s /opt/proxmox-api/scripts/pxm /usr/local/bin/pxm

# Set Python path
ENV PYTHONPATH=/opt/proxmox-api/scripts/lib:$PYTHONPATH

ENTRYPOINT ["/entrypoint.sh"]
CMD ["pxm", "help"]
