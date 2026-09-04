#!/usr/bin/env bash
set -Eeuo pipefail

source /opt/unitree-runtime/activate.sh
cd /workspace/unitree-try
python scripts/smoke_mujoco.py
cd "${ISAACLAB_PATH}"
timeout 180 ./isaaclab.sh -p /workspace/unitree-try/scripts/smoke_isaac.py --headless
