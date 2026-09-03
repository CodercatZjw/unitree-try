#!/usr/bin/env bash
set -Eeuo pipefail

UNITREE_ROOT="${UNITREE_ROOT:-/workspace/unitree-runtime}"
source "${UNITREE_ROOT}/activate.sh"

echo "=== System ==="
uname -srmo
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
df -h "${UNITREE_ROOT}"

echo
echo "=== Python / simulation ==="
python - <<'PY'
import sys
from importlib.metadata import version
import torch

print("python:", sys.version.split()[0])
print("torch:", torch.__version__)
print("torch CUDA:", torch.version.cuda)
print("Isaac Sim:", version("isaacsim"))
print("Isaac Lab:", version("isaaclab"))
print("MuJoCo:", version("mujoco"))
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("GPU:", torch.cuda.get_device_name(0))
PY

echo
echo "=== Pinned source revisions ==="
for repo in IsaacLab unitree_ros unitree_sdk2 unitree_mujoco; do
  path="${UNITREE_ROOT}/third_party/${repo}"
  printf '%-16s %s\n' "${repo}" "$(git -C "${path}" rev-parse --short HEAD 2>/dev/null || echo missing)"
done

echo
echo "=== Installed robot assets ==="
test -f "${UNITREE_MUJOCO_PATH}/unitree_robots/a2/scene_terrain.xml" && echo "A2/A2 Pro MuJoCo: OK"
test -f "${ISAACLAB_PATH}/source/isaaclab_tasks/isaaclab_tasks/manager_based/locomotion/velocity/config/g1/flat_env_cfg.py" \
  && echo "G1 flat/rough tasks: OK"
test -f "${ISAACLAB_PATH}/source/isaaclab_tasks/isaaclab_tasks/manager_based/locomotion/velocity/config/g1/run_env_cfg.py" \
  && echo "G1 running task: OK"
test -f "${ISAACLAB_PATH}/source/isaaclab_tasks/isaaclab_tasks/manager_based/locomotion/velocity/config/h1/flat_env_cfg.py" \
  && echo "H1 flat/rough tasks: OK"
