#
# Provides a deploy image for Trellis with:
# - Ubuntu   24.04
# - Ansible  v2.19.7
# - Node.js  22
# - Yarn
#
FROM ubuntu:24.04

LABEL author="Thomas Georgel <thomas@hydrat.agency>"

# Adding Yarn package repository
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y curl \
    && curl -sL https://deb.nodesource.com/setup_22.x | bash \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Installing Ansible's prerequisites (Python libs via apt — avoids PEP 668 / pip-on-Debian issues)
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
        build-essential \
        python3 python3-dev python3-packaging python3-resolvelib \
        python3-setuptools python3-wheel \
        python3-yaml python3-jinja2 python3-pycryptodome python3-winrm \
        libffi-dev libssl-dev libpq-dev libldap2-dev \
        libxml2-dev libxslt1-dev libsasl2-dev libjpeg-dev zlib1g-dev \
        git

# Downloading Ansible's source tree
RUN git clone https://github.com/ansible/ansible.git --recursive \
    && cd ansible \
    && git fetch origin v2.19.7 \
    && git checkout v2.19.7

# Compiling Ansible
RUN cd ansible \
    && bash -c 'source ./hacking/env-setup'

# Moving useful Ansible stuff to /opt/ansible
RUN mkdir -p /opt/ansible \
    && mv /ansible/bin  /opt/ansible/bin \
    && mv /ansible/lib  /opt/ansible/lib \
    && rm -rf /ansible

# Installing Node.js and Yarn
RUN apt-get install -y nodejs yarn

# Installing handy tools
RUN apt-get install -y sshpass openssh-client rsync

# Symlink python 3 as python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Clean up
RUN apt-get remove -y --auto-remove \
        python3-dev \
        libffi-dev \
        libpq-dev \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev \
        libssl-dev \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Adding hosts for convenience
RUN mkdir -p /etc/ansible \
    && echo 'localhost' > /etc/ansible/hosts

# Define environment variables (key=value avoids BuildKit legacy/undefined-var warnings)
ENV PATH=/opt/ansible/bin:$PATH \
    PYTHONPATH=/opt/ansible/lib \
    MANPATH=/opt/ansible/docs/man

# Install Ansible collections
RUN ansible-galaxy collection install community.general \
    && ansible-galaxy collection install ansible.posix

# Default command: displays tool versions
CMD [ "sh", "-c", "echo \"Ansible: \\e[32m$(ansible --version | cut -d ' ' -f 2 | tr -d '\\n')\\e[39m\\nNode:    \\e[32m$(node --version | cut -d 'v' -f 2)\\e[39m\\nYarn:    \\e[32m$(yarn --version)\\e[39m\"" ]
