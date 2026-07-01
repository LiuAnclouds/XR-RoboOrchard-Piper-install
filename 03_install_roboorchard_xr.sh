#!/usr/bin/env bash
set -euo pipefail

DOCKER_NAME=${DOCKER_NAME:-holobrain}
SOP_DIR=${SOP_DIR:-$HOME/SOP}
CONTAINER_ROOT=${CONTAINER_ROOT:-/moonxkj}
ROBO_PATH=${ROBO_PATH:-$CONTAINER_ROOT/RoboOrchard}
PYBIND_PATH=${PYBIND_PATH:-$CONTAINER_ROOT/XRoboToolkit-PC-Service-Pybind}
DEB_PATH=${DEB_PATH:-$SOP_DIR/XRoboToolkit-PC-Service-Pybind/tmp/XRoboToolkit-PC-Service/XRoboToolkit-PC-Service_1.0.0.0_arm64.deb}
PC_SERVICE_DEB_URL=${PC_SERVICE_DEB_URL:-https://github.com/XR-Robotics/XRoboToolkit-PC-Service/releases/download/v1.0.0/XRoboToolkit-PC-Service_1.0.0.0_arm64.deb}
ICU73_URL=${ICU73_URL:-https://download.qt.io/development_releases/prebuilt/icu/prebuilt/73.2/icu-linux-g++-Debian11.6-aarch64.7z}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PATCH_CPP=${PATCH_CPP:-$SCRIPT_DIR/patches/pybind_patch.cpp}

echo "[0/4] Install host launch tools"
sudo apt-get update
sudo apt-get install -y tmux pipx
python3 -m pipx ensurepath || true
python3 -m pipx install tmuxp --force
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"

echo "[1/4] Install RoboOrchard in Docker"
docker exec -i "$DOCKER_NAME" bash <<BASH
set -e
if [ ! -d "$ROBO_PATH/.git" ]; then echo "RoboOrchard source is not mounted at $ROBO_PATH" >&2; exit 1; fi
git config --global --add safe.directory '*'
cd "$ROBO_PATH"
git submodule update --init --recursive
python3 -m pip install --upgrade pip
python3 -m venv venv/roboorchard-venv || true
source venv/roboorchard-venv/bin/activate
python -m pip install --upgrade pip wheel
make dev-env
make install-editable
pip cache purge || true
make ros2-dev-env
cd "$ROBO_PATH/ros2_package"
rm -rf build install log
source /opt/ros/humble/setup.bash
source "$ROBO_PATH/venv/roboorchard-venv/bin/activate"
make build
BASH

echo "[note] piper_sdk is installed separately by bash 04_install_piper_sdk.sh"

echo "[2/4] Install XRoboToolkit pybind with pybind_patch.cpp"
if [ ! -f "$PATCH_CPP" ]; then echo "pybind patch not found: $PATCH_CPP" >&2; exit 1; fi
docker cp "$PATCH_CPP" "$DOCKER_NAME:/tmp/pybind_patch.cpp"
docker exec -i \
  -e ROBO_PATH="$ROBO_PATH" \
  -e PYBIND_PATH="$PYBIND_PATH" \
  "$DOCKER_NAME" bash <<'BASH'
set -e
source "$ROBO_PATH/venv/roboorchard-venv/bin/activate"
cd "$PYBIND_PATH"

# Follow the official XRoboToolkit-PC-Service-Pybind Orin setup flow first.
bash setup_orin.sh

# Then apply our full pybind replacement and rebuild the Python extension.
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
sudo apt-get update
sudo apt-get install -y wget p7zip-full qt6-base-dev qt6-tools-dev qt6-tools-dev-tools libqt6core5compat6-dev
if [ ! -f "$DEB_PATH" ]; then
  echo "PC Service deb not found locally, downloading official release..."
  tmp_deb=/tmp/XRoboToolkit-PC-Service_1.0.0.0_arm64.deb
  wget -O "$tmp_deb" "$PC_SERVICE_DEB_URL"
  sudo mkdir -p "$(dirname "$DEB_PATH")"
  sudo install -m 0644 "$tmp_deb" "$DEB_PATH"
fi
sudo dpkg -i "$DEB_PATH"
cd /opt/apps/roboticsservice
if ! ls lib/libicu*.so.73* >/dev/null 2>&1; then
  echo "Installing ICU73 libraries for PC Service..."
  tmp_icu=/tmp/icu73-aarch64.7z
  tmp_icu_dir=/tmp/icu73-aarch64
  rm -rf "$tmp_icu_dir"
  mkdir -p "$tmp_icu_dir"
  wget -O "$tmp_icu" "$ICU73_URL"
  7z x -y "$tmp_icu" -o"$tmp_icu_dir" >/dev/null
  sudo mkdir -p lib
  find "$tmp_icu_dir" -type f -name 'libicu*.so.73*' -exec sudo cp -a {} lib/ \;
  cd lib
  for f in libicu*.so.73.*; do
    [ -e "$f" ] || continue
    base=${f%.*}
    sudo ln -sf "$f" "$base"
  done
  cd ..
fi
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


echo "Install complete. Next: bash 04_install_piper_sdk.sh"
