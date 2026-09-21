# CoreDNS Tools Environment
# DNS debugging and management tools for CoreDNS on k3s-util
FROM alpine:latest

LABEL maintainer="homelab"
LABEL description="DNS debugging and management tools"

# Install DNS tools
RUN apk add --no-cache \
    bash \
    bind-tools \
    drill \
    ldns \
    curl \
    jq \
    wget \
    netcat-openbsd \
    tcpdump \
    whois

# Create helper scripts
RUN mkdir -p /usr/local/bin

# Script to query CoreDNS
COPY scripts/dns-query /usr/local/bin/dns-query
COPY scripts/dns-check /usr/local/bin/dns-check
COPY scripts/dns-trace /usr/local/bin/dns-trace
COPY scripts/list-records /usr/local/bin/list-records

RUN chmod +x /usr/local/bin/dns-*  /usr/local/bin/list-records

# Default DNS server (k3s-util CoreDNS)
ENV DNS_SERVER=192.0.2.169

WORKDIR /workspace

CMD ["/bin/bash"]
