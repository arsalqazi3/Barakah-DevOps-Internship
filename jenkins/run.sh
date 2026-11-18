#!/usr/bin/env bash
set -euo pipefail
docker build -t barakah-jenkins "$(dirname "$0")"
docker volume create jenkins_home
docker run -d --name jenkins --restart unless-stopped \
  -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$(stat -c %g /var/run/docker.sock)" \
  barakah-jenkins
