#!/usr/bin/env bash
set -euo pipefail

SOP_DIR=${SOP_DIR:-$HOME/SOP}
ROBO_REPO=${ROBO_REPO:-https://github.com/HorizonRobotics/RoboOrchard.git}
IMAGE_NAME=${IMAGE_NAME:-holobrain-dev:latest}
UPSTREAM_IMAGE=${UPSTREAM_IMAGE:-horizonrobotics/holobrain:v0-ubuntu22.04-py3.10-ros-humble-torch2.8.0}

mkdir -p "$SOP_DIR"
if [ ! -d "$SOP_DIR/RoboOrchard/.git" ]; then
  rm -rf "$SOP_DIR/RoboOrchard"
  git clone "$ROBO_REPO" "$SOP_DIR/RoboOrchard"
fi

cd "$SOP_DIR/RoboOrchard"
git submodule update --init --recursive

bash projects/HoloBrain/dev/build.sh
docker tag "$UPSTREAM_IMAGE" "$IMAGE_NAME"
echo "Built image: $IMAGE_NAME from RoboOrchard native Dockerfile"
