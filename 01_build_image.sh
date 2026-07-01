#!/usr/bin/env bash
set -euo pipefail
IMAGE_NAME=${IMAGE_NAME:-holobrain-dev:s100}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
docker build \
  --network host \
  --build-arg ROS_DISTRO=humble \
  --build-arg USE_ALIYUN_MIRROR=${USE_ALIYUN_MIRROR:-1} \
  --build-arg INSTALL_TORCH=${INSTALL_TORCH:-1} \
  -t "$IMAGE_NAME" \
  -f "$SCRIPT_DIR/Dockerfile.holobrain" \
  "$SCRIPT_DIR"
echo "Built image: $IMAGE_NAME"
