#!/usr/bin/env bash
set -euo pipefail

DOCKER_NAME=${DOCKER_NAME:-holobrain}
SOP_DIR=${SOP_DIR:-$HOME/SOP}
ROBO_PATH=/moonxkj/RoboOrchard
DEB_PATH=${DEB_PATH:-$SOP_DIR/XRoboToolkit-PC-Service-Pybind/tmp/XRoboToolkit-PC-Service/XRoboToolkit-PC-Service_1.0.0.0_arm64.deb}
RIGHT_READY=${RIGHT_READY:-"[-0.108, 0.096, -1.026, 0.174, 1.077, -0.045, 0.0]"}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PATCH_CPP=${PATCH_CPP:-$SCRIPT_DIR/patches/pybind_patch.cpp}

echo "[1/4] Install RoboOrchard in Docker"
docker exec -i "$DOCKER_NAME" bash <<BASH
set -e
if [ ! -d "$ROBO_PATH/.git" ]; then echo "RoboOrchard source is not mounted at $ROBO_PATH" >&2; exit 1; fi
python3 -m venv $ROBO_PATH/venv/roboorchard-venv || true
source $ROBO_PATH/venv/roboorchard-venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
cd $ROBO_PATH
pip install -e python/robo_orchard_core || true
pip install -e python/robo_orchard_schemas || true
pip install -e python/robo_orchard_lab || true
cd $ROBO_PATH/ros2_package
source /opt/ros/humble/setup.bash
colcon build --symlink-install
BASH

echo "[note] piper_sdk is installed separately by bash install_piper_sdk.sh"

echo "[2/4] Install XRoboToolkit pybind with pybind_patch.cpp"
if [ ! -f "$PATCH_CPP" ]; then echo "pybind patch not found: $PATCH_CPP" >&2; exit 1; fi
docker cp "$PATCH_CPP" "$DOCKER_NAME:/tmp/pybind_patch.cpp"
docker exec -i "$DOCKER_NAME" bash <<'BASH'
set -e
source /moonxkj/RoboOrchard/venv/roboorchard-venv/bin/activate
cd /moonxkj/XRoboToolkit-PC-Service-Pybind
cp /tmp/pybind_patch.cpp bindings/py_bindings.cpp
export LD_LIBRARY_PATH=$PWD/lib/aarch64:$PWD/lib:$LD_LIBRARY_PATH
pip uninstall -y xrobotoolkit_sdk || true
python setup.py install
python - <<'PY'
import xrobotoolkit_sdk as xrt
print('xrobotoolkit_sdk import OK')
print('has get_latest_message:', hasattr(xrt, 'get_latest_message'))
PY
BASH

echo "[3/4] Install host PC Service and patch runService.sh"
if [ ! -f "$DEB_PATH" ]; then echo "PC Service deb not found: $DEB_PATH" >&2; exit 1; fi
sudo apt-get update
sudo apt-get install -y qt6-base-dev qt6-tools-dev qt6-tools-dev-tools libqt6core5compat6-dev
sudo dpkg -i "$DEB_PATH"
cd /opt/apps/roboticsservice
sudo tee runService.sh > /dev/null <<'RUNSERVICE'
#!/bin/bash
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

pids=$(pgrep -f "^$DIR/RoboticsServiceProcess$|^\./RoboticsServiceProcess$" || true)
if [ -n "$pids" ]; then
  echo "Stopping old RoboticsServiceProcess: $pids"
  kill $pids 2>/dev/null || true
  sleep 1
  pids=$(pgrep -f "^$DIR/RoboticsServiceProcess$|^\./RoboticsServiceProcess$" || true)
  if [ -n "$pids" ]; then
    echo "Force stopping old RoboticsServiceProcess: $pids"
    kill -9 $pids 2>/dev/null || true
  fi
fi

export LD_LIBRARY_PATH=$DIR:$DIR/lib:$DIR/SDK/arm64:$LD_LIBRARY_PATH
export QT_PLUGIN_PATH=$DIR/plugins/:$QT_PLUGIN_PATH
export QT_QML_PATH=$DIR/qml/:$QT_QML_PATH
echo $LD_LIBRARY_PATH
echo $QT_PLUGIN_PATH
echo $QT_QML_PATH
cd $DIR
./RoboticsServiceProcess &
RUNSERVICE
sudo chmod +x runService.sh RoboticsServiceProcess
LD_LIBRARY_PATH=$PWD:$PWD/lib:$PWD/SDK/arm64 ldd ./RoboticsServiceProcess | grep "not found" && exit 2 || echo "ldd OK: no missing libs"

echo "[4/4] Patch HoloBrain launch RIGHT_READY"
LAUNCH=$SOP_DIR/RoboOrchard/projects/HoloBrain/launch/templates/launch.yaml
cp "$LAUNCH" "$LAUNCH.before-sop-install-$(date +%Y%m%d-%H%M%S)"
python3 - <<PY
from pathlib import Path
import re
p=Path('$LAUNCH')
s=p.read_text()
s=re.sub(r'RIGHT_READY: "[^"]+"', 'RIGHT_READY: "$RIGHT_READY"', s, count=1)
p.write_text(s)
PY
grep -n 'RIGHT_READY' "$LAUNCH"

echo "Install complete. Next: bash install_piper_sdk.sh, then bash start.sh, then bash check.sh"
