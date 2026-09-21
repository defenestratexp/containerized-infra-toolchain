# Cloudflare CLI/API interaction container
# Secrets fetched from AWS Secrets Manager at runtime via entrypoint.sh
FROM alpine:latest

RUN set -x && \
    for i in 1 2 3 4 5; do \
        apk add --no-cache \
            bash \
            curl \
            jq \
            ca-certificates \
            coreutils \
            aws-cli && \
        break || \
        if [ $i -lt 5 ]; then \
            echo "Retrying package installation (attempt $i/5)..." && \
            sleep 5; \
        else \
            echo "Failed to install packages after 5 attempts" && \
            exit 1; \
        fi; \
    done

COPY entrypoint.sh /entrypoint.sh
COPY scripts/ /usr/local/bin/
RUN chmod +x /entrypoint.sh /usr/local/bin/*

WORKDIR /workspace

RUN cat >> /root/.bashrc << 'EOF'
echo "Cloudflare Tools Available:"
echo ""
echo "  cf-help                                    - Show this help"
echo "  cf-tunnel-list                             - List ingress rules in homelab tunnel"
echo "  cf-tunnel-add-hostname <host> <service>    - Add public hostname to tunnel"
echo "  cf-tunnel-del-hostname <host>              - Remove hostname from tunnel"
echo "  cf-tunnel-config                           - Print full tunnel config (JSON)"
echo "  cf-zone-list                               - List Cloudflare DNS zones"
echo ""
echo "Tunnel: homelab  Account: $CF_ACCOUNT_ID"
echo ""
EOF

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
