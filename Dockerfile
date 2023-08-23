#
# Provides a deploy image for Trellis with:
# - Ubuntu   22.04
# - Ansible  2.15.3
# - Node.js  14
# - Yarn
#
FROM ubuntu:22.04

LABEL author="Thomas Georgel <thomas@hydrat.agency>"

# Adding Yarn package repository
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y curl \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Installing Ansible's prerequisites
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
        build-essential \
        python3 python3-pip python3-dev python3-packaging python3-resolvelib \
        libffi-dev libssl-dev libpq-dev libldap2-dev \
        libxml2-dev libxslt1-dev libsasl2-dev libjpeg-dev zlib1g-dev \
        git

# Upgrading pip
# @see https://github.com/pypa/pip/issues/5240#issuecomment-383129401
RUN python3 -m pip install --upgrade pip \
    && pip install --upgrade setuptools wheel \
    && pip install --upgrade pyyaml jinja2 pycryptodome \
    && pip install --upgrade pywinrm

# Downloading Ansible's source tree
RUN git clone https://github.com/ansible/ansible.git --recursive \
    && cd ansible \
    && git fetch origin v2.15.3 \
    && git checkout v2.15.3

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
        python3-pip \
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

# Define environment variables
ENV PATH             /opt/ansible/bin:$PATH
ENV PYTHONPATH       /opt/ansible/lib:$PYTHONPATH
ENV MANPATH          /opt/ansible/docs/man:$MANPATH

# Install Ansible collections
RUN ansible-galaxy collection install community.general \
    && ansible-galaxy collection install ansible.posix

# Default command: displays tool versions
CMD [ "sh", "-c", "echo \"Ansible: \\e[32m$(ansible --version | cut -d ' ' -f 2 | tr -d '\\n')\\e[39m\\nNode:    \\e[32m$(node --version | cut -d 'v' -f 2)\\e[39m\\nYarn:    \\e[32m$(yarn --version)\\e[39m\"" ]
