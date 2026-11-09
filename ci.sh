#!/usr/bin/env bash
set -euo pipefail
echo "Build #${BUILD_NUMBER:-local}, commit ${GIT_COMMIT:-unknown}"
python3 -m venv .venv
. .venv/bin/activate
pip install -q -r requirements.txt
pytest -q
echo "All tests passed"
