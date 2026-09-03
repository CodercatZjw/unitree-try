#!/usr/bin/env bash

_unitree_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "${_unitree_root}/.venv/bin/activate" ]]; then
  echo "Unitree runtime is incomplete: ${_unitree_root}" >&2
  return 1 2>/dev/null || exit 1
fi

unset CONDA_PREFIX CONDA_DEFAULT_ENV
source "${_unitree_root}/.venv/bin/activate"
export UNITREE_ROOT="${_unitree_root}"
export ISAACLAB_PATH="${_unitree_root}/third_party/IsaacLab"
export UNITREE_ROS_PATH="${_unitree_root}/third_party/unitree_ros"
export UNITREE_SDK2_PATH="${_unitree_root}/third_party/unitree_sdk2"
export UNITREE_MUJOCO_PATH="${_unitree_root}/third_party/unitree_mujoco"
export CMAKE_PREFIX_PATH="${_unitree_root}/.local${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export LD_LIBRARY_PATH="${_unitree_root}/.local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export OMNI_KIT_ACCEPT_EULA=YES
export PYTHONUNBUFFERED=1
export TERM="${TERM:-xterm-256color}"

echo "Unitree environment activated: ${UNITREE_ROOT}"
