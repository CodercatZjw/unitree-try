#!/usr/bin/env bash
# Reproducible Unitree A2 Pro, G1, and H1 simulation environment.
set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
BUNDLE_ROOT="$(cd "$(dirname "${SCRIPT_PATH}")/.." && pwd)"
UNITREE_ROOT="${UNITREE_ROOT:-/workspace/unitree-runtime}"
ISAAC_SIM_VERSION="${ISAAC_SIM_VERSION:-5.1.0}"
ISAACLAB_REF="${ISAACLAB_REF:-37ddf626871758333d6ed89cf64ad702aef127d0}"
UNITREE_ROS_REF="${UNITREE_ROS_REF:-7d6075f7f58588b189b940130e3edab3c839b2df}"
UNITREE_SDK2_REF="${UNITREE_SDK2_REF:-9754cd153af3da471b0fe5f3aa535e426fb11db3}"
UNITREE_MUJOCO_REF="${UNITREE_MUJOCO_REF:-4134cb5dc7ff1ba7f484deda48b5274b58694519}"
MUJOCO_VERSION="${MUJOCO_VERSION:-3.3.6}"
SKIP_SMOKE_TESTS="${SKIP_SMOKE_TESTS:-0}"

THIRD_PARTY="${UNITREE_ROOT}/third_party"
VENV="${UNITREE_ROOT}/.venv"
LOCAL_PREFIX="${UNITREE_ROOT}/.local"
CACHE_DIR="${UNITREE_ROOT}/.cache"
LOG_DIR="${UNITREE_ROOT}/logs"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run with sudo: sudo -E bash scripts/setup_unitree_env.sh" >&2
  exit 1
fi
if [[ ! -f /etc/os-release ]] || ! grep -qi ubuntu /etc/os-release; then
  echo "This installer supports Ubuntu 22.04 or 24.04." >&2
  exit 1
fi
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "NVIDIA driver/GPU is required; nvidia-smi was not found." >&2
  exit 1
fi

mkdir -p "${UNITREE_ROOT}" "${THIRD_PARTY}" "${CACHE_DIR}" "${LOG_DIR}" "${LOCAL_PREFIX}"
exec > >(tee -a "${LOG_DIR}/setup.log") 2>&1

on_error() {
  local code=$?
  echo "[ERROR] Setup failed at line ${BASH_LINENO[0]} (exit ${code})."
  echo "Re-run the same command to continue; completed work is reused."
  exit "${code}"
}
trap on_error ERR

export DEBIAN_FRONTEND=noninteractive
export OMNI_KIT_ACCEPT_EULA=YES
export PYTHONUNBUFFERED=1
export PIP_CACHE_DIR="${CACHE_DIR}/pip"
export TERM=xterm-256color

DRIVER_VERSION="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)"
DRIVER_MAJOR="${DRIVER_VERSION%%.*}"
RENDERING_STATUS=available
if [[ "${DRIVER_MAJOR}" =~ ^[0-9]+$ ]] && (( DRIVER_MAJOR < 580 )); then
  echo "[WARN] Driver ${DRIVER_VERSION} is older than the validated 580-series baseline."
fi
if [[ "${ISAAC_SIM_VERSION}" == 5.1.* && "${DRIVER_VERSION}" == 595.* ]]; then
  RENDERING_STATUS=blocked-by-driver-595
  echo "[WARN] Driver ${DRIVER_VERSION} can crash the Isaac Sim 5.1 RTX renderer."
  echo "[WARN] Headless physics may work, but use a 580-series host for video/cameras."
fi

echo "[1/11] Installing Ubuntu packages"
apt-get update
apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build git git-lfs curl ca-certificates pkg-config pipx \
  libeigen3-dev libyaml-cpp-dev libspdlog-dev libfmt-dev libboost-program-options-dev \
  libglfw3-dev libgl1 libglu1-mesa libegl1 libx11-6 libxext6 libxi6 libxrandr2 \
  libxinerama1 libxcursor1 libxkbcommon0 libsm6 libice6 libxt6 libvulkan1 \
  vulkan-tools ffmpeg
git lfs install --system

echo "[2/11] Installing uv and Python 3.11"
if ! command -v uv >/dev/null 2>&1; then
  PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install uv
fi
uv python install 3.11
if [[ ! -x "${VENV}/bin/python" ]]; then
  uv venv --python 3.11 --seed "${VENV}"
fi
unset CONDA_PREFIX CONDA_DEFAULT_ENV
source "${VENV}/bin/activate"
python -m pip install --upgrade pip
python -m pip install setuptools==80.9.0 wheel==0.44.0

if ! python -m pip show isaacsim >/dev/null 2>&1; then
  free_kb="$(df --output=avail "${UNITREE_ROOT}" | tail -1 | tr -d ' ')"
  if (( free_kb < 30 * 1024 * 1024 )); then
    echo "A fresh installation requires at least 30 GB free in ${UNITREE_ROOT}." >&2
    exit 1
  fi
fi

echo "[3/11] Installing Isaac Sim ${ISAAC_SIM_VERSION}"
python -m pip install "isaacsim[all,extscache]==${ISAAC_SIM_VERSION}" \
  --extra-index-url https://pypi.nvidia.com

echo "[4/11] Installing CUDA 12.8 PyTorch"
python -m pip install --upgrade torch==2.7.0 torchvision==0.22.0 \
  --index-url https://download.pytorch.org/whl/cu128

clone_at_ref() {
  local url="$1" destination="$2" ref="$3"
  local freshly_cloned=0
  if [[ ! -d "${destination}/.git" ]]; then
    git clone --filter=blob:none --no-checkout "${url}" "${destination}"
    freshly_cloned=1
  fi
  git -C "${destination}" fetch --depth 1 origin "${ref}"
  if (( freshly_cloned )) || [[ ! -e "${destination}/.git/index" ]]; then
    git -C "${destination}" checkout --detach FETCH_HEAD
  elif [[ -n "$(git -C "${destination}" status --porcelain --untracked-files=no)" ]]; then
    echo "[WARN] Keeping local changes in ${destination}."
  else
    git -C "${destination}" checkout --detach FETCH_HEAD
  fi
}

echo "[5/11] Fetching pinned Isaac Lab and Unitree sources"
clone_at_ref https://github.com/isaac-sim/IsaacLab.git "${THIRD_PARTY}/IsaacLab" "${ISAACLAB_REF}"
clone_at_ref https://github.com/unitreerobotics/unitree_ros.git "${THIRD_PARTY}/unitree_ros" "${UNITREE_ROS_REF}"
clone_at_ref https://github.com/unitreerobotics/unitree_sdk2.git "${THIRD_PARTY}/unitree_sdk2" "${UNITREE_SDK2_REF}"
clone_at_ref https://github.com/unitreerobotics/unitree_mujoco.git "${THIRD_PARTY}/unitree_mujoco" "${UNITREE_MUJOCO_REF}"

echo "[6/11] Applying repository-maintained Isaac Lab tasks"
shopt -s nullglob
for patch in "${BUNDLE_ROOT}"/patches/isaaclab/*.patch; do
  if git -C "${THIRD_PARTY}/IsaacLab" apply --reverse --check "${patch}" >/dev/null 2>&1; then
    echo "Already applied: $(basename "${patch}")"
  else
    git -C "${THIRD_PARTY}/IsaacLab" apply --check "${patch}"
    git -C "${THIRD_PARTY}/IsaacLab" apply "${patch}"
    echo "Applied: $(basename "${patch}")"
  fi
done
shopt -u nullglob

echo "[7/11] Installing Isaac Lab with RSL-RL"
cd "${THIRD_PARTY}/IsaacLab"
python -m pip install --no-build-isolation flatdict==4.0.1
./isaaclab.sh -i rsl_rl
uv pip install --editable "${THIRD_PARTY}/IsaacLab/source/isaaclab"
python -m pip install \
  packaging==23.0 psutil==5.9.8 typing_extensions==4.12.2 wheel==0.44.0 \
  ipython==9.4.0 onnx==1.18.0 mujoco==${MUJOCO_VERSION}
python -c 'import isaaclab; print("Isaac Lab:", isaaclab.__file__)'

echo "[8/11] Building Unitree SDK2"
cmake -S "${THIRD_PARTY}/unitree_sdk2" -B "${THIRD_PARTY}/unitree_sdk2/build" \
  -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${LOCAL_PREFIX}"
cmake --build "${THIRD_PARTY}/unitree_sdk2/build" --parallel "$(nproc)"
cmake --install "${THIRD_PARTY}/unitree_sdk2/build"

echo "[9/11] Building the Unitree MuJoCo simulator"
MUJOCO_ARCHIVE="${CACHE_DIR}/mujoco-${MUJOCO_VERSION}-linux-x86_64.tar.gz"
MUJOCO_DIR="${THIRD_PARTY}/mujoco-${MUJOCO_VERSION}"
if [[ ! -d "${MUJOCO_DIR}" ]]; then
  curl -fL --retry 5 --retry-delay 2 \
    "https://github.com/google-deepmind/mujoco/releases/download/${MUJOCO_VERSION}/mujoco-${MUJOCO_VERSION}-linux-x86_64.tar.gz" \
    -o "${MUJOCO_ARCHIVE}"
  tar -xzf "${MUJOCO_ARCHIVE}" -C "${THIRD_PARTY}"
fi
ln -sfn "${MUJOCO_DIR}" "${THIRD_PARTY}/unitree_mujoco/simulate/mujoco"
cmake -S "${THIRD_PARTY}/unitree_mujoco/simulate" \
  -B "${THIRD_PARTY}/unitree_mujoco/simulate/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${LOCAL_PREFIX}"
cmake --build "${THIRD_PARTY}/unitree_mujoco/simulate/build" \
  --target unitree_mujoco --parallel "$(nproc)"

echo "[10/11] Installing activation file and recording versions"
install -m 755 "${BUNDLE_ROOT}/scripts/activate.sh" "${UNITREE_ROOT}/activate.sh"
cat > "${UNITREE_ROOT}/VERSIONS.lock" <<VERSIONS
python=$(python --version 2>&1 | awk '{print $2}')
torch=$(python -c 'import torch; print(torch.__version__)')
isaacsim=$(python -c 'from importlib.metadata import version; print(version("isaacsim"))')
isaaclab=$(python -c 'from importlib.metadata import version; print(version("isaaclab"))')
mujoco=$(python -c 'from importlib.metadata import version; print(version("mujoco"))')
nvidia_driver=${DRIVER_VERSION}
isaac_rendering=${RENDERING_STATUS}
IsaacLab=$(git -C "${THIRD_PARTY}/IsaacLab" rev-parse HEAD)
unitree_ros=$(git -C "${THIRD_PARTY}/unitree_ros" rev-parse HEAD)
unitree_sdk2=$(git -C "${THIRD_PARTY}/unitree_sdk2" rev-parse HEAD)
unitree_mujoco=$(git -C "${THIRD_PARTY}/unitree_mujoco" rev-parse HEAD)
VERSIONS

echo "[11/11] Running smoke tests"
if [[ "${SKIP_SMOKE_TESTS}" == "1" ]]; then
  echo "Smoke tests skipped by SKIP_SMOKE_TESTS=1."
else
  export UNITREE_ROOT
  python "${BUNDLE_ROOT}/scripts/smoke_mujoco.py"
  cd "${THIRD_PARTY}/IsaacLab"
  timeout 180 ./isaaclab.sh -p "${BUNDLE_ROOT}/scripts/smoke_isaac.py" --headless
fi

echo
echo "Unitree environment is ready at ${UNITREE_ROOT}"
echo "Activate it with: source ${UNITREE_ROOT}/activate.sh"
if [[ "${RENDERING_STATUS}" != available ]]; then
  echo "RTX video rendering is disabled by the current driver compatibility warning."
fi
