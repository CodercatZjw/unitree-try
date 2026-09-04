#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p \
  /workspace/unitree-artifacts/isaaclab-logs \
  /workspace/unitree-artifacts/checkpoints \
  /workspace/unitree-artifacts/videos

printf '%s\n' 'source /opt/unitree-runtime/activate.sh' > /etc/profile.d/unitree-runtime.sh
chmod 0644 /etc/profile.d/unitree-runtime.sh
source /opt/unitree-runtime/activate.sh
