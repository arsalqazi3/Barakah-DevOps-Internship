FROM jenkins/jenkins:lts-jdk21
USER root

# Python for tests, plus tools needed below
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-pip curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI only (the daemon is the EC2 host's, reached through the socket)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI v2
RUN curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

# Snyk CLI (Task 2)
RUN curl -fsSL https://downloads.snyk.io/cli/stable/snyk-linux -o /usr/local/bin/snyk \
    && chmod +x /usr/local/bin/snyk

USER jenkins
