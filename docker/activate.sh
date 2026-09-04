#!/usr/bin/env bash

if [[ ! -x /workspace/isaaclab/isaaclab.sh ]]; then
  echo "Isaac Lab is missing from /workspace/isaaclab" >&2
  return 1 2>/dev/null || exit 1
fi

export UNITREE_ROOT="/opt/unitree-runtime"
export ISAACLAB_PATH="/workspace/isaaclab"
export UNITREE_ROS_PATH="${UNITREE_ROOT}/third_party/unitree_ros"
export UNITREE_SDK2_PATH="${UNITREE_ROOT}/third_party/unitree_sdk2"
export UNITREE_MUJOCO_PATH="${UNITREE_ROOT}/third_party/unitree_mujoco"
export PATH="${UNITREE_ROOT}/bin:${PATH}"
export CMAKE_PREFIX_PATH="${UNITREE_ROOT}/.local${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export LD_LIBRARY_PATH="${UNITREE_ROOT}/.local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export OMNI_KIT_ACCEPT_EULA=YES
export ACCEPT_EULA=Y
export PYTHONUNBUFFERED=1
if [[ -z "${TERM:-}" || "${TERM}" == "dumb" ]]; then
  export TERM=xterm-256color
fi

echo "Unitree Docker environment activated: ${UNITREE_ROOT}"
