# kubectl environment for k3s-util K3s cluster
# Kubeconfig fetched from AWS Secrets Manager at runtime via entrypoint.sh
FROM alpine:latest

# Install packages with retry logic for flaky Alpine mirrors
RUN set -x && \
    for i in 1 2 3 4 5; do \
        apk add --no-cache \
            bash curl wget jq git ca-certificates gettext openssl aws-cli && \
        break || \
        { echo "Retry $i..."; sleep 2; }; \
    done

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm get_helm.sh

# Install k9s for cluster exploration
RUN wget -O k9s.tar.gz "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz" && \
    tar -xzf k9s.tar.gz k9s && \
    mv k9s /usr/local/bin/ && \
    rm k9s.tar.gz

# Copy entrypoint and scripts
COPY entrypoint.sh /entrypoint.sh
COPY scripts/ /usr/local/bin/
RUN chmod +x /entrypoint.sh /usr/local/bin/*

# Set environment variables
ENV KUBECONFIG=/root/.kube/config
ENV CLUSTER_NAME=k3s-util

# Create working directories
WORKDIR /workspace
RUN mkdir -p /root/.kube /manifests

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
