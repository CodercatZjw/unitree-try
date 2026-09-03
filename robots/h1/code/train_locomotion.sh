#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-flat}"
UNITREE_ROOT="${UNITREE_ROOT:-/workspace/unitree-runtime}"
NUM_ENVS="${NUM_ENVS:-1024}"
MAX_ITERATIONS="${MAX_ITERATIONS:-1500}"
VIDEO_INTERVAL="${VIDEO_INTERVAL:-5000}"
VIDEO_LENGTH="${VIDEO_LENGTH:-300}"
RECORD_VIDEO="${RECORD_VIDEO:-1}"
RESUME="${RESUME:-0}"
LOAD_RUN="${LOAD_RUN:-.*}"
CHECKPOINT="${CHECKPOINT:-model_.*.pt}"

case "${MODE}" in
  flat) TASK=Isaac-Velocity-Flat-H1-v0; RUN_NAME="${RUN_NAME:-h1_flat}" ;;
  rough) TASK=Isaac-Velocity-Rough-H1-v0; RUN_NAME="${RUN_NAME:-h1_rough}" ;;
  *) echo "Usage: $0 {flat|rough}" >&2; exit 2 ;;
esac

source "${UNITREE_ROOT}/activate.sh"
cd "${ISAACLAB_PATH}"
args=(
  -p scripts/reinforcement_learning/rsl_rl/train.py
  --task "${TASK}" --num_envs "${NUM_ENVS}"
  --max_iterations "${MAX_ITERATIONS}" --run_name "${RUN_NAME}" --headless
)
[[ "${RECORD_VIDEO}" == "1" ]] && args+=(--video --video_interval "${VIDEO_INTERVAL}" --video_length "${VIDEO_LENGTH}")
[[ "${RESUME}" == "1" ]] && args+=(--resume --load_run "${LOAD_RUN}" --checkpoint "${CHECKPOINT}")
exec ./isaaclab.sh "${args[@]}"
