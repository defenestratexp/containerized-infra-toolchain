# Atlassian Cloud API tools (Jira + Confluence). FROM the shared homelab base.
FROM homelab-tools-base:latest
COPY lib/atlassian.sh /lib/atlassian.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
