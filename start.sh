#!/usr/bin/env bash
set -euo pipefail
SOP_DIR=${SOP_DIR:-/home/sunrise/moonxkj/SOP}
LAUNCH_DIR=${LAUNCH_DIR:-$SOP_DIR/RoboOrchard/projects/HoloBrain/launch/templates}

echo "[1/2] Start PC Service"
cd /opt/apps/roboticsservice
./runService.sh
sleep 2
pgrep -af '[R]oboticsServiceProcess'
ss -lntp | grep -E ':60061|:63901'

echo "[2/2] Start HoloBrain tmux session"
tmux kill-session -t holobrain 2>/dev/null || true
cd "$LAUNCH_DIR"
/home/sunrise/.local/bin/tmuxp load -d launch.yaml
tmux ls
