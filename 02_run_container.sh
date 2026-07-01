#!/usr/bin/env bash
set -euo pipefail

DOCKER_NAME=${DOCKER_NAME:-holobrain}
IMAGE_NAME=${IMAGE_NAME:-holobrain-dev:s100}
SOP_DIR=${SOP_DIR:-$HOME/SOP}
CONTAINER_ROOT=${CONTAINER_ROOT:-/moonxkj}

ROBO_REPO=${ROBO_REPO:-https://github.com/HorizonRobotics/RoboOrchard.git}
PYBIND_REPO=${PYBIND_REPO:-https://github.com/XR-Robotics/XRoboToolkit-PC-Service-Pybind.git}
PIPER_REPO=${PIPER_REPO:-https://github.com/agilexrobotics/piper_sdk.git}

# Clone the source trees that are mounted by the verified runtime container.
if [ ! -d "$SOP_DIR/RoboOrchard/.git" ]; then
  rm -rf "$SOP_DIR/RoboOrchard"
  git clone "$ROBO_REPO" "$SOP_DIR/RoboOrchard"
fi

cd "$SOP_DIR/RoboOrchard"
git submodule update --init --recursive

if [ ! -d "$SOP_DIR/XRoboToolkit-PC-Service-Pybind/.git" ]; then
  rm -rf "$SOP_DIR/XRoboToolkit-PC-Service-Pybind"
  git clone "$PYBIND_REPO" "$SOP_DIR/XRoboToolkit-PC-Service-Pybind"
fi

if [ ! -d "$SOP_DIR/piper_sdk/.git" ]; then
  rm -rf "$SOP_DIR/piper_sdk"
  git clone "$PIPER_REPO" "$SOP_DIR/piper_sdk"
fi

# XRoboToolkit-Teleop-Sample-Python is handled by the pybind install flow if needed.
# It is not part of the verified runtime container mounts.

docker rm -f "$DOCKER_NAME" >/dev/null 2>&1 || true

docker run -itd \
  --name "$DOCKER_NAME" \
  --user root \
  --shm-size=4g \
  --ipc host \
  --network host \
  --pid host \
  --rm \
  --privileged \
  -e USER=${USER:-sunrise} \
  -e DOCKER_USER=${USER:-sunrise} \
  -e PYTHONUNBUFFERED=1 \
  -e ROS_DOMAIN_ID=2 \
  -e ROS2_INSTALL_PATH=/opt/ros/humble/ \
  -e no_proxy="localhost,127.0.0.1" \
  -v /dev:/dev \
  -e CONTAINER_ROOT="$CONTAINER_ROOT" \
  -v "$SOP_DIR/RoboOrchard:$CONTAINER_ROOT/RoboOrchard" \
  -v "$SOP_DIR/XRoboToolkit-PC-Service-Pybind:$CONTAINER_ROOT/XRoboToolkit-PC-Service-Pybind" \
  -v "$SOP_DIR/piper_sdk:$CONTAINER_ROOT/piper_sdk" \
  -w "$CONTAINER_ROOT" \
  "$IMAGE_NAME" \
  bash

docker ps --filter "name=$DOCKER_NAME"
