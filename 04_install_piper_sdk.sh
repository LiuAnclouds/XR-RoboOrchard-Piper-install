#!/usr/bin/env bash
set -euo pipefail
DOCKER_NAME=${DOCKER_NAME:-holobrain}
PIPER_PATH=${PIPER_PATH:-/moonxkj/piper_sdk}

# piper_sdk is intentionally installed separately from the Docker image.
docker exec -i \
  -e PIPER_PATH="$PIPER_PATH" \
  "$DOCKER_NAME" bash <<'BASH'
set -e
if [ ! -d "$PIPER_PATH" ]; then
  echo "piper_sdk source is not mounted at $PIPER_PATH" >&2
  exit 1
fi
source /moonxkj/RoboOrchard/venv/roboorchard-venv/bin/activate
cd "$PIPER_PATH"
pip uninstall -y piper_sdk piper-sdk || true
pip install -e .
cd /tmp
python - <<'PY'
from piper_sdk import C_PiperInterface_V2
print('piper_sdk import OK')
PY
BASH
