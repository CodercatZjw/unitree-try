#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p \
  /workspace/unitree-artifacts/isaaclab-logs \
  /workspace/unitree-artifacts/checkpoints \
  /workspace/unitree-artifacts/videos

source /opt/unitree-runtime/activate.sh
exec "$@"
