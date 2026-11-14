#!/usr/bin/env bash
set -euo pipefail
: "${SNYK_TOKEN:?SNYK_TOKEN is not set}"
echo "Running Snyk Code SAST scan"
snyk code test --severity-threshold=medium
echo "SAST gate passed"
