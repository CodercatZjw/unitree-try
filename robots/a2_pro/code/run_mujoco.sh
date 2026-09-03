#!/usr/bin/env bash
set -Eeuo pipefail

UNITREE_ROOT="${UNITREE_ROOT:-/workspace/unitree-runtime}"
source "${UNITREE_ROOT}/activate.sh"

sim_dir="${UNITREE_MUJOCO_PATH}/simulate"
binary="${sim_dir}/build/unitree_mujoco"
scene="${sim_dir}/unitree_robots/a2/scene_terrain.xml"

if [[ ! -x "${binary}" ]]; then
  echo "Simulator is not built. Re-run scripts/setup_unitree_env.sh" >&2
  exit 1
fi
if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
  echo "No desktop display detected. Use scripts/smoke_mujoco.py for headless validation." >&2
  exit 1
fi

cd "${sim_dir}"
exec "${binary}" -r "${scene}"
