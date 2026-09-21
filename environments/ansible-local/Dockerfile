# Local Ansible execution environment
# SSH key fetched from AWS Secrets Manager at runtime via entrypoint.sh
FROM alpine:latest

# Install packages with retry logic
RUN set -x && \
    for i in 1 2 3 4 5; do \
        apk add --no-cache \
            bash curl wget jq openssh-client sshpass git \
            python3 py3-pip ca-certificates rsync aws-cli && \
        break || \
        { echo "Retry $i..."; sleep 2; }; \
    done

# Install Ansible and required collections
RUN pip3 install --break-system-packages \
    ansible \
    ansible-core \
    pyyaml \
    jinja2 \
    boto3 \
    botocore

# Install common Ansible collections
RUN ansible-galaxy collection install \
    ansible.posix \
    community.general \
    community.docker \
    amazon.aws

# Create ansible wrapper script for easy playbook execution
RUN cat > /usr/local/bin/run-playbook << 'SCRIPT' && chmod +x /usr/local/bin/run-playbook
#!/bin/bash
PLAYBOOK_DIR=${PLAYBOOK_DIR:-/workspace}
INVENTORY_FILE=${INVENTORY_FILE:-inventory/hosts}

if [ $# -eq 0 ]; then
    echo "Usage: run-playbook <playbook.yml> [additional args]"
    echo ""
    echo "Available playbooks in $PLAYBOOK_DIR/playbooks/:"
    find "$PLAYBOOK_DIR/playbooks" -name "*.yml" -type f 2>/dev/null | sort || echo "No playbooks found"
    exit 1
fi

PLAYBOOK="$1"
shift

if [[ ! "$PLAYBOOK" =~ ^playbooks/ ]] && [[ ! "$PLAYBOOK" =~ ^/ ]]; then
    PLAYBOOK="playbooks/$PLAYBOOK"
fi

cd "$PLAYBOOK_DIR"
echo "Running: ansible-playbook -i $INVENTORY_FILE $PLAYBOOK $@"
ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK" "$@"
SCRIPT

# Create script to list available playbooks
RUN cat > /usr/local/bin/list-playbooks << 'SCRIPT' && chmod +x /usr/local/bin/list-playbooks
#!/bin/bash
PLAYBOOK_DIR=${PLAYBOOK_DIR:-/workspace}
echo "Available playbooks in $PLAYBOOK_DIR/playbooks/:"
find "$PLAYBOOK_DIR/playbooks" -name "*.yml" -type f 2>/dev/null | sed 's|^.*/playbooks/||' | sort || echo "No playbooks found"
SCRIPT

# Create script to test connectivity
RUN cat > /usr/local/bin/ping-all << 'SCRIPT' && chmod +x /usr/local/bin/ping-all
#!/bin/bash
PLAYBOOK_DIR=${PLAYBOOK_DIR:-/workspace}
INVENTORY_FILE=${INVENTORY_FILE:-inventory/hosts}
cd "$PLAYBOOK_DIR"
echo "Testing connectivity to all hosts..."
ansible all -i "$INVENTORY_FILE" -m ping
SCRIPT

# Create script to run ad-hoc commands
RUN cat > /usr/local/bin/run-command << 'SCRIPT' && chmod +x /usr/local/bin/run-command
#!/bin/bash
PLAYBOOK_DIR=${PLAYBOOK_DIR:-/workspace}
INVENTORY_FILE=${INVENTORY_FILE:-inventory/hosts}

if [ $# -lt 2 ]; then
    echo "Usage: run-command <host_group> <command>"
    exit 1
fi

GROUP="$1"
COMMAND="$2"
cd "$PLAYBOOK_DIR"
echo "Running command on $GROUP..."
ansible "$GROUP" -i "$INVENTORY_FILE" -m shell -a "$COMMAND"
SCRIPT

# Set environment variables
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_SSH_PIPELINING=True
ENV PLAYBOOK_DIR=/workspace
ENV INVENTORY_FILE=inventory/hosts

# Create working directory and SSH directory
WORKDIR /workspace
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Entrypoint copies mounted key to proper location with correct permissions
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
