#!/usr/bin/env bash
set -u

DOCKER_NAME=${DOCKER_NAME:-holobrain}
SOP_DIR=${SOP_DIR:-$HOME/SOP}
CONTAINER_ROOT=${CONTAINER_ROOT:-/moonxkj}
ROBO_PATH=${ROBO_PATH:-$CONTAINER_ROOT/RoboOrchard}
PYBIND_PATH=${PYBIND_PATH:-$CONTAINER_ROOT/XRoboToolkit-PC-Service-Pybind}
PIPER_PATH=${PIPER_PATH:-$CONTAINER_ROOT/piper_sdk}
FAILED=0

ok() { echo "[OK] $*"; }
fail() { echo "[FAIL] $*"; FAILED=1; }
warn() { echo "[WARN] $*"; }

section() {
  echo
  echo "========== $* =========="
}

check_container() {
  section "0. Docker container"
  if docker ps --format '{{.Names}}' | grep -qx "$DOCKER_NAME"; then
    ok "Docker container '$DOCKER_NAME' is running"
  else
    fail "Docker container '$DOCKER_NAME' is not running. Run: bash 02_run_container.sh"
    return 1
  fi
}

check_roboorchard() {
  section "1. RoboOrchard + ROS2"
  docker exec -i -e ROBO_PATH="$ROBO_PATH" "$DOCKER_NAME" bash <<'BASH'
set -e
if [ ! -d "$ROBO_PATH" ]; then
  echo "[FAIL] $ROBO_PATH is missing"
  exit 10
fi
if [ ! -f "$ROBO_PATH/venv/roboorchard-venv/bin/activate" ]; then
  echo "[FAIL] RoboOrchard venv is missing. Run: bash 03_install_roboorchard_xr.sh"
  exit 11
fi
source "$ROBO_PATH/venv/roboorchard-venv/bin/activate"
python - <<'PY'
from importlib import metadata
for pkg in ('robo_orchard_core', 'robo_orchard_lab'):
    metadata.version(pkg)
    print(f'[OK] Python package installed: {pkg}')
import robo_orchard_core
print('[OK] robo_orchard_core import OK')
PY
if [ ! -f "$ROBO_PATH/ros2_package/install/setup.bash" ]; then
  echo "[FAIL] RoboOrchard ROS2 install/setup.bash is missing. Run: bash 03_install_roboorchard_xr.sh"
  exit 12
fi
source /opt/ros/humble/setup.bash
source "$ROBO_PATH/ros2_package/install/setup.bash"
pkg_list=$(mktemp)
ros2 pkg list > "$pkg_list"
missing=0
for pkg in \
  robo_orchard_data_msg_ros2 \
  robo_orchard_pico_msg_ros2 \
  robo_orchard_teleop_msg_ros2 \
  robo_orchard_piper_msg_ros2 \
  robo_orchard_teleop_ros2; do
  if grep -qx "$pkg" "$pkg_list"; then
    echo "[OK] ROS2 package found: $pkg"
  else
    echo "[FAIL] ROS2 package missing: $pkg"
    missing=1
  fi
done
if [ -d "$ROBO_PATH/ros2_package/install/robo_orchard_piper_ros2" ]; then
  echo "[OK] ROS2 package installed: robo_orchard_piper_ros2"
else
  echo "[FAIL] ROS2 package install dir missing: robo_orchard_piper_ros2"
  missing=1
fi
rm -f "$pkg_list"
exit $missing
BASH
  local rc=$?
  if [ $rc -ne 0 ]; then
    fail "RoboOrchard environment is incomplete"
  else
    ok "RoboOrchard environment is complete"
  fi
}

check_xr_pybind() {
  section "2. XRoboToolkit PC Service Pybind"
  docker exec -i -e ROBO_PATH="$ROBO_PATH" -e PYBIND_PATH="$PYBIND_PATH" "$DOCKER_NAME" bash <<'BASH'
set -e
if [ ! -d "$PYBIND_PATH" ]; then
  echo "[FAIL] $PYBIND_PATH is missing"
  exit 20
fi
source "$ROBO_PATH/venv/roboorchard-venv/bin/activate"
cd /tmp
python - <<'PY'
import xrobotoolkit_sdk as xrt
print('[OK] xrobotoolkit_sdk import OK')
print('[OK] get_latest_message:', hasattr(xrt, 'get_latest_message'))
if not hasattr(xrt, 'get_latest_message'):
    raise SystemExit(1)
PY
BASH
  local rc=$?
  if [ $rc -ne 0 ]; then
    fail "XRoboToolkit pybind environment is incomplete. Run: bash 03_install_roboorchard_xr.sh"
  else
    ok "XRoboToolkit pybind environment is complete"
  fi
}

check_piper_sdk() {
  section "3. piper_sdk"
  docker exec -i -e ROBO_PATH="$ROBO_PATH" -e PIPER_PATH="$PIPER_PATH" "$DOCKER_NAME" bash <<'BASH'
set -e
if [ ! -d "$PIPER_PATH" ]; then
  echo "[FAIL] $PIPER_PATH is missing"
  exit 30
fi
source "$ROBO_PATH/venv/roboorchard-venv/bin/activate"
cd /tmp
python - <<'PY'
from piper_sdk import C_PiperInterface_V2
print('[OK] piper_sdk import OK')
PY
BASH
  local rc=$?
  if [ $rc -ne 0 ]; then
    fail "piper_sdk environment is incomplete. Run: bash 04_install_piper_sdk.sh"
  else
    ok "piper_sdk environment is complete"
  fi
}

check_pc_service() {
  section "4. Host PC Service"
  if [ ! -x /opt/apps/roboticsservice/RoboticsServiceProcess ]; then
    fail "PC Service executable is missing: /opt/apps/roboticsservice/RoboticsServiceProcess"
    echo "[FAIL] Run: bash 03_install_roboorchard_xr.sh"
    return 0
  fi
  if [ ! -x /opt/apps/roboticsservice/runService.sh ]; then
    fail "PC Service runService.sh is missing or not executable"
    return 0
  fi
  cd /opt/apps/roboticsservice || return 0
  if LD_LIBRARY_PATH=$PWD:$PWD/lib:$PWD/SDK/arm64 ldd ./RoboticsServiceProcess | grep -q "not found"; then
    fail "PC Service has missing shared libraries"
    LD_LIBRARY_PATH=$PWD:$PWD/lib:$PWD/SDK/arm64 ldd ./RoboticsServiceProcess | grep "not found" || true
  else
    ok "PC Service ldd OK"
  fi
}

check_container && {
  check_roboorchard
  check_xr_pybind
  check_piper_sdk
}
check_pc_service

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All required environment checks passed."
  exit 0
else
  echo "Some environment checks failed. Fix the [FAIL] sections above."
  exit 1
fi
