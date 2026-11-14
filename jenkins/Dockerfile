FROM jenkins/jenkins:lts-jdk21
USER root
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-venv python3-pip curl && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://downloads.snyk.io/cli/stable/snyk-linux -o /usr/local/bin/snyk && chmod +x /usr/local/bin/snyk
USER jenkins
