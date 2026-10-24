#!/usr/bin/env bash
set -euo pipefail
docker build -t barakah-jenkins "$(dirname "$0")"
docker volume create jenkins_home
docker run -d --name jenkins --restart unless-stopped \
  -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  barakah-jenkins
