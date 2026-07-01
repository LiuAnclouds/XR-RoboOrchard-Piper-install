#!/usr/bin/env bash
set -euo pipefail
DOCKER_NAME=${DOCKER_NAME:-holobrain}

echo '--- PC Service ---'
pgrep -af '[R]oboticsServiceProcess' || true
ss -lntp | grep -E ':60061|:63901' || true
ss -ntp | grep RoboticsService || true

echo '--- Docker ---'
docker ps --filter "name=$DOCKER_NAME"

echo '--- Control processes ---'
pgrep -af 'single_ctrl|piper_pico_vr_teleop|pico_bridge|rosbridge' || true

echo '--- ROS topics ---'
docker exec "$DOCKER_NAME" bash -lc 'source /moonxkj/RoboOrchard/venv/roboorchard-venv/bin/activate && source /moonxkj/RoboOrchard/ros2_package/install/setup.bash && ros2 topic list | grep -E "puppet|robot/right|pico|joint" | sort' || true

echo '--- CPU ---'
ps -eo pid,ppid,pcpu,pmem,comm,args --sort=-pcpu | head -25
