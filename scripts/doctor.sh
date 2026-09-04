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
import os
import sys
from importlib.metadata import PackageNotFoundError, version
import torch


def package_version(name: str, fallback_env: str) -> str:
    try:
        return version(name)
    except PackageNotFoundError:
        return os.environ.get(fallback_env) or "packaged-image"


print("python:", sys.version.split()[0])
print("torch:", torch.__version__)
print("torch CUDA:", torch.version.cuda)
print("Isaac Sim release:", package_version("isaacsim", "ISAACSIM_VERSION"))
print("Isaac Lab image release:", os.environ.get("ISAACLAB_VERSION") or "source-checkout")
print("Isaac Lab Python package:", package_version("isaaclab", "ISAACLAB_VERSION"))
print("MuJoCo:", version("mujoco"))
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("GPU:", torch.cuda.get_device_name(0))
PY

echo
echo "=== Pinned source revisions ==="
for repo in IsaacLab unitree_ros unitree_sdk2 unitree_mujoco; do
  if [[ "${repo}" == "IsaacLab" ]]; then
    path="${ISAACLAB_PATH}"
  else
    path="${UNITREE_ROOT}/third_party/${repo}"
  fi
  if revision="$(git -C "${path}" rev-parse --short HEAD 2>/dev/null)"; then
    printf '%-16s %s\n' "${repo}" "${revision}"
  elif [[ "${repo}" == "IsaacLab" && -x "${path}/isaaclab.sh" ]]; then
    printf '%-16s %s\n' "${repo}" "packaged-image"
  else
    printf '%-16s %s\n' "${repo}" missing
  fi
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
