# Network Debug Environment
# Comprehensive network troubleshooting toolkit
FROM alpine:latest

LABEL maintainer="homelab"
LABEL description="Network debugging and troubleshooting tools"

# Install network tools
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    jq \
    bind-tools \
    iputils \
    mtr \
    netcat-openbsd \
    nmap \
    nmap-scripts \
    tcpdump \
    iperf3 \
    iproute2 \
    net-tools \
    ethtool \
    traceroute \
    openssh-client \
    openssl \
    socat \
    busybox-extras \
    tshark

# Create helper scripts
COPY scripts/port-check /usr/local/bin/port-check
COPY scripts/http-check /usr/local/bin/http-check
COPY scripts/network-scan /usr/local/bin/network-scan
COPY scripts/latency-test /usr/local/bin/latency-test
COPY scripts/host-info /usr/local/bin/host-info

RUN chmod +x /usr/local/bin/port-check \
    /usr/local/bin/http-check \
    /usr/local/bin/network-scan \
    /usr/local/bin/latency-test \
    /usr/local/bin/host-info

WORKDIR /workspace

CMD ["/bin/bash"]
