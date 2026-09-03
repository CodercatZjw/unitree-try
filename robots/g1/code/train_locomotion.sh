#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-walk}"
UNITREE_ROOT="${UNITREE_ROOT:-/workspace/unitree-runtime}"
NUM_ENVS="${NUM_ENVS:-1024}"
VIDEO_LENGTH="${VIDEO_LENGTH:-300}"
RECORD_VIDEO="${RECORD_VIDEO:-1}"
RESUME="${RESUME:-0}"
LOAD_RUN="${LOAD_RUN:-.*}"
CHECKPOINT="${CHECKPOINT:-model_.*.pt}"

case "${MODE}" in
  walk)
    TASK=Isaac-Velocity-Flat-G1-v0
    MAX_ITERATIONS="${MAX_ITERATIONS:-1500}"
    VIDEO_INTERVAL="${VIDEO_INTERVAL:-5000}"
    RUN_NAME="${RUN_NAME:-g1_walk}"
    ;;
  rough)
    TASK=Isaac-Velocity-Rough-G1-v0
    MAX_ITERATIONS="${MAX_ITERATIONS:-2000}"
    VIDEO_INTERVAL="${VIDEO_INTERVAL:-5000}"
    RUN_NAME="${RUN_NAME:-g1_rough}"
    ;;
  run)
    TASK=Isaac-Velocity-Run-G1-v0
    MAX_ITERATIONS="${MAX_ITERATIONS:-1200}"
    VIDEO_INTERVAL="${VIDEO_INTERVAL:-2500}"
    RUN_NAME="${RUN_NAME:-g1_run}"
    ;;
  *)
    echo "Usage: $0 {walk|rough|run}" >&2
    exit 2
    ;;
esac

source "${UNITREE_ROOT}/activate.sh"
cd "${ISAACLAB_PATH}"

args=(
  -p scripts/reinforcement_learning/rsl_rl/train.py
  --task "${TASK}"
  --num_envs "${NUM_ENVS}"
  --max_iterations "${MAX_ITERATIONS}"
  --run_name "${RUN_NAME}"
  --headless
)

if [[ "${RECORD_VIDEO}" == "1" ]]; then
  args+=(--video --video_interval "${VIDEO_INTERVAL}" --video_length "${VIDEO_LENGTH}")
fi
if [[ "${RESUME}" == "1" ]]; then
  args+=(--resume --load_run "${LOAD_RUN}" --checkpoint "${CHECKPOINT}")
fi

exec ./isaaclab.sh "${args[@]}"
