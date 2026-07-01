#!/usr/bin/env bash
set -euo pipefail
DOCKER_NAME=${DOCKER_NAME:-holobrain}
PIPER_PATH=${PIPER_PATH:-/moonxkj/piper_sdk}
PIPER_ROS_REPO=${PIPER_ROS_REPO:-https://github.com/agilexrobotics/piper_ros.git}
PIPER_URDF_NAME=${PIPER_URDF_NAME:-piper_no_gripper_description.urdf}

# piper_sdk is intentionally installed separately from the Docker image.
docker exec -i "$DOCKER_NAME" bash <<BASH
set -e
if [ ! -d "$PIPER_PATH" ]; then
  echo "piper_sdk source is not mounted at $PIPER_PATH" >&2
  exit 1
fi
source /moonxkj/RoboOrchard/venv/roboorchard-venv/bin/activate
cd "$PIPER_PATH"
pip uninstall -y piper_sdk piper-sdk || true
pip install -e .

mkdir -p "$PIPER_PATH/assets/urdf" "$PIPER_PATH/assets/meshes" /tmp/piper_assets
if [ ! -d /tmp/piper_assets/piper_ros/.git ]; then
  rm -rf /tmp/piper_assets/piper_ros
  git clone --depth 1 "$PIPER_ROS_REPO" /tmp/piper_assets/piper_ros
fi

urdf_src=$(find /tmp/piper_assets/piper_ros -type f -name "$PIPER_URDF_NAME" | head -1)
if [ -z "$urdf_src" ]; then
  echo "URDF not found in piper_ros: $PIPER_URDF_NAME" >&2
  exit 2
fi
cp "$urdf_src" "$PIPER_PATH/assets/urdf/$PIPER_URDF_NAME"

mesh_dir=$(find /tmp/piper_assets/piper_ros -type d -path '*/piper_description/meshes' | head -1)
if [ -n "$mesh_dir" ]; then
  cp -a "$mesh_dir/." "$PIPER_PATH/assets/meshes/"
fi

python - <<'PY'
from pathlib import Path
from piper_sdk import C_PiperInterface_V2
urdf = Path('/moonxkj/piper_sdk/assets/urdf/piper_no_gripper_description.urdf')
print('piper_sdk import OK')
print('piper URDF:', urdf, 'exists=', urdf.exists())
if not urdf.exists():
    raise SystemExit(1)
PY
BASH
