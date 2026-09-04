#!/usr/bin/env bash
# Reproducible Unitree A2/A2 Pro, G1 and H1 environment for AutoDL.
set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
A2_ROOT="${A2_ROOT:-/root/autodl-tmp/a2-pro}"
PERSIST_ROOT="${PERSIST_ROOT:-/root/autodl-fs/a2-data}"
NETWORK_MODE="${NETWORK_MODE:-cn}" # cn or proxy; never combine both
CLASH_PROXY="${CLASH_PROXY:-http://127.0.0.1:7890}"
ISAAC_SIM_VERSION="${ISAAC_SIM_VERSION:-5.1.0}"
ISAACLAB_REF="${ISAACLAB_REF:-37ddf626871758333d6ed89cf64ad702aef127d0}" # v2.3.2
UNITREE_ROS_REF="${UNITREE_ROS_REF:-7d6075f7f58588b189b940130e3edab3c839b2df}"
UNITREE_SDK2_REF="${UNITREE_SDK2_REF:-9754cd153af3da471b0fe5f3aa535e426fb11db3}"
UNITREE_MUJOCO_REF="${UNITREE_MUJOCO_REF:-4134cb5dc7ff1ba7f484deda48b5274b58694519}"
MUJOCO_VERSION="${MUJOCO_VERSION:-3.3.6}"

THIRD_PARTY="${A2_ROOT}/third_party"
VENV="${A2_ROOT}/.venv"
LOCAL_PREFIX="${A2_ROOT}/.local"
CACHE_DIR="${A2_ROOT}/.cache"
LOG_DIR="${A2_ROOT}/logs"
MINICONDA_HOME="${A2_ROOT}/.miniconda"

case "${NETWORK_MODE}" in
  cn)
    MINICONDA_URL="${MINICONDA_URL:-https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py311_26.7.1-1-Linux-x86_64.sh}"
    PYPI_MIRROR="${PYPI_MIRROR:-https://mirrors.aliyun.com/pypi/simple/}"
    PYTORCH_MIRROR="${PYTORCH_MIRROR:-https://mirrors.aliyun.com/pytorch-wheels/cu128}"
    NVIDIA_PYPI="${NVIDIA_PYPI:-https://pypi.nvidia.cn}"
    ;;
  proxy)
    MINICONDA_URL="${MINICONDA_URL:-https://repo.anaconda.com/miniconda/Miniconda3-py311_26.7.1-1-Linux-x86_64.sh}"
    PYPI_MIRROR="${PYPI_MIRROR:-https://pypi.org/simple}"
    PYTORCH_MIRROR="${PYTORCH_MIRROR:-https://download.pytorch.org/whl/cu128}"
    NVIDIA_PYPI="${NVIDIA_PYPI:-https://pypi.nvidia.com}"
    ;;
  *)
    echo "NETWORK_MODE must be cn or proxy" >&2
    exit 2
    ;;
esac

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root on an AutoDL/SeetaCloud instance." >&2
  exit 1
fi

mkdir -p \
  "${A2_ROOT}" "${THIRD_PARTY}" "${CACHE_DIR}" "${LOG_DIR}" \
  "${PERSIST_ROOT}" /workspace

if [[ "${A2_ROOT}" != "/workspace/a2-pro" && ! -e /workspace/a2-pro ]]; then
  ln -s "${A2_ROOT}" /workspace/a2-pro
fi
if [[ "${SCRIPT_PATH}" != "${A2_ROOT}/setup_a2_pro.sh" ]]; then
  install -m 755 "${SCRIPT_PATH}" "${A2_ROOT}/setup_a2_pro.sh"
fi
PERSIST_SETUP_PATH="$(readlink -m "${PERSIST_ROOT}/setup_a2_pro_cn.sh")"
if [[ "${SCRIPT_PATH}" != "${PERSIST_SETUP_PATH}" ]]; then
  install -m 755 "${SCRIPT_PATH}" "${PERSIST_SETUP_PATH}"
fi

exec > >(tee -a "${LOG_DIR}/setup.log") 2>&1

on_error() {
  local code=$?
  echo "[ERROR] Setup failed at line ${BASH_LINENO[0]} (exit ${code})."
  echo "[ERROR] Re-run this script to continue; completed downloads and installs are reused."
  exit "${code}"
}
trap on_error ERR

export DEBIAN_FRONTEND=noninteractive
export OMNI_KIT_ACCEPT_EULA=YES
export PYTHONUNBUFFERED=1
export PIP_CACHE_DIR="${CACHE_DIR}/pip"
export PIP_DEFAULT_TIMEOUT=180
export TERM=xterm-256color

# APT uses the domestic source configured by the AutoDL image. Keep all proxy
# variables off during this phase so domestic mirrors and Clash never overlap.
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY || true

NVIDIA_DRIVER_VERSION="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || true)"
if [[ -z "${NVIDIA_DRIVER_VERSION}" ]]; then
  echo "nvidia-smi could not detect a GPU or NVIDIA driver." >&2
  exit 1
fi

ISAAC_RENDERING_STATUS="available"
if [[ "${ISAAC_SIM_VERSION}" == 5.1.* && "${NVIDIA_DRIVER_VERSION}" == 595.* ]]; then
  ISAAC_RENDERING_STATUS="blocked-by-driver-595"
  echo "[WARN] Driver ${NVIDIA_DRIVER_VERSION} has produced Isaac Sim 5.1 RTX renderer crashes in this project."
  echo "[WARN] Headless physics may work, but camera/video/GUI can fail in librtx.scenedb.plugin.so."
  echo "[WARN] Use a compatible host or migrate Isaac Sim and Isaac Lab as a matched pair."
fi

echo "[1/10] Installing Ubuntu dependencies"
apt-get update
apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build git git-lfs curl aria2 ca-certificates pkg-config tmux rsync \
  libeigen3-dev libyaml-cpp-dev libspdlog-dev libfmt-dev \
  libboost-program-options-dev libglfw3-dev \
  libgl1 libglu1-mesa libegl1 libx11-6 libxext6 libxi6 libxrandr2 \
  libxinerama1 libxcursor1 libxkbcommon0 libsm6 libice6 libxt6 \
  libvulkan1 vulkan-tools ffmpeg
git lfs install --system

if [[ "${NETWORK_MODE}" == "proxy" ]]; then
  curl -x "${CLASH_PROXY}" -fsS --max-time 15 \
    https://www.google.com/generate_204 -o /dev/null
  export http_proxy="${CLASH_PROXY}" https_proxy="${CLASH_PROXY}"
  export HTTP_PROXY="${CLASH_PROXY}" HTTPS_PROXY="${CLASH_PROXY}"
else
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY || true
fi
export PIP_INDEX_URL="${PYPI_MIRROR}"

echo "[2/10] Creating the Python 3.11 environment"
MINICONDA_INSTALLER="${CACHE_DIR}/miniconda-py311.sh"
if [[ ! -x "${MINICONDA_HOME}/bin/conda" ]]; then
  aria2c --continue=true --max-connection-per-server=8 --split=8 \
    --min-split-size=1M --file-allocation=none --auto-file-renaming=false \
    --allow-overwrite=true --dir "${CACHE_DIR}" \
    --out "$(basename "${MINICONDA_INSTALLER}")" "${MINICONDA_URL}"
  bash "${MINICONDA_INSTALLER}" -b -p "${MINICONDA_HOME}"
fi
if [[ -e "${VENV}" && ! -x "${VENV}/bin/python" ]]; then
  mv "${VENV}" "${VENV}.partial.$(date +%Y%m%d-%H%M%S)"
fi
if [[ ! -e "${VENV}" ]]; then
  ln -s "${MINICONDA_HOME}" "${VENV}"
fi

unset CONDA_PREFIX CONDA_DEFAULT_ENV
source "${VENV}/bin/activate"
python -m pip install --upgrade pip
python -m pip install setuptools==80.9.0 wheel==0.44.0

if ! python -m pip show isaacsim >/dev/null 2>&1; then
  free_kb="$(df --output=avail "${A2_ROOT}" | tail -1 | tr -d ' ')"
  if (( free_kb < 25 * 1024 * 1024 )); then
    echo "At least 25 GB of free disk is required for a fresh Isaac Sim install." >&2
    exit 1
  fi
fi

echo "[3/10] Installing Isaac Sim ${ISAAC_SIM_VERSION}"
python -m pip install "isaacsim[all,extscache]==${ISAAC_SIM_VERSION}" \
  --index-url "${PYPI_MIRROR}" --extra-index-url "${NVIDIA_PYPI}"

echo "[4/10] Verifying the PyTorch 2.7 GPU runtime"
# Isaac Sim 5.1 installs a validated PyTorch 2.7 build. Do not download the
# same Python version and another complete CUDA runtime if this build works.
if python - <<'PY'
import sys
import torch
import torchvision

ok = (
    torch.__version__.split("+")[0] == "2.7.0"
    and torchvision.__version__.split("+")[0] == "0.22.0"
    and torch.cuda.is_available()
)
print(f"PyTorch {torch.__version__}, torchvision {torchvision.__version__}, CUDA {torch.version.cuda}")
sys.exit(0 if ok else 1)
PY
then
  echo "The installed PyTorch runtime can use the GPU; no duplicate CUDA download is needed."
else
  python -m pip install --upgrade --force-reinstall \
    torch==2.7.0 torchvision==0.22.0 \
    --index-url "${PYTORCH_MIRROR}"
fi

clone_at_ref() {
  local url="$1"
  local destination="$2"
  local ref="$3"
  local freshly_cloned=0

  if [[ ! -d "${destination}/.git" ]]; then
    git clone --filter=blob:none --no-checkout "${url}" "${destination}"
    freshly_cloned=1
  fi
  git -C "${destination}" fetch --depth 1 origin "${ref}"
  if (( freshly_cloned )) || [[ ! -e "${destination}/.git/index" ]]; then
    git -C "${destination}" checkout --detach FETCH_HEAD
  elif [[ -n "$(git -C "${destination}" status --porcelain --untracked-files=no)" ]]; then
    echo "[WARN] Keeping local modifications in ${destination}; not switching its revision."
  else
    git -C "${destination}" checkout --detach FETCH_HEAD
  fi
}

echo "[5/10] Fetching pinned Isaac Lab and Unitree sources"
if [[ "${NETWORK_MODE}" == "cn" && -f /etc/network_turbo ]]; then
  # AutoDL's academic accelerator is used only for GitHub resources.
  set +u
  source /etc/network_turbo
  set -u
fi
clone_at_ref https://github.com/isaac-sim/IsaacLab.git \
  "${THIRD_PARTY}/IsaacLab" "${ISAACLAB_REF}"
clone_at_ref https://github.com/unitreerobotics/unitree_ros.git \
  "${THIRD_PARTY}/unitree_ros" "${UNITREE_ROS_REF}"
clone_at_ref https://github.com/unitreerobotics/unitree_sdk2.git \
  "${THIRD_PARTY}/unitree_sdk2" "${UNITREE_SDK2_REF}"
clone_at_ref https://github.com/unitreerobotics/unitree_mujoco.git \
  "${THIRD_PARTY}/unitree_mujoco" "${UNITREE_MUJOCO_REF}"
if [[ "${NETWORK_MODE}" == "cn" ]]; then
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY || true
fi

mkdir -p "${PERSIST_ROOT}/isaaclab_logs"
if [[ ! -e "${THIRD_PARTY}/IsaacLab/logs" ]]; then
  ln -s "${PERSIST_ROOT}/isaaclab_logs" "${THIRD_PARTY}/IsaacLab/logs"
fi

echo "[6/10] Installing Isaac Lab and RSL-RL"
cd "${THIRD_PARTY}/IsaacLab"
# Isaac Lab 2.3.2 otherwise replaces every non-cu128 PyTorch wheel. Accept a
# working PyTorch 2.7 CUDA build verified above and avoid a second runtime.
sed -i \
  's/if \[\[ "$cur" == "$want_torch" \]\]; then/if [[ "$cur" == "$want_torch" || ( "${cur%%+*}" == "${torch_ver}" \&\& "$cur" == *"+cu"* ) ]]; then/' \
  "${THIRD_PARTY}/IsaacLab/isaaclab.sh"
python -m pip install --no-build-isolation flatdict==4.0.1
./isaaclab.sh -i rsl_rl
python -m pip install --editable "${THIRD_PARTY}/IsaacLab/source/isaaclab"
# Restore Isaac Sim 5.1 runtime pins after optional Isaac Lab packages resolve.
python -m pip install \
  packaging==23.0 psutil==5.9.8 typing_extensions==4.12.2 wheel==0.44.0 \
  ipython==9.4.0 onnx==1.18.0 mujoco==3.3.6
python -c 'import isaaclab; print("Isaac Lab core:", isaaclab.__file__)'

echo "[7/10] Building and installing Unitree SDK2"
cmake -S "${THIRD_PARTY}/unitree_sdk2" \
  -B "${THIRD_PARTY}/unitree_sdk2/build" \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${LOCAL_PREFIX}"
cmake --build "${THIRD_PARTY}/unitree_sdk2/build" --parallel "$(nproc)"
cmake --install "${THIRD_PARTY}/unitree_sdk2/build"

echo "[8/10] Building the official Unitree MuJoCo DDS simulator"
MUJOCO_ARCHIVE="${CACHE_DIR}/mujoco-${MUJOCO_VERSION}-linux-x86_64.tar.gz"
MUJOCO_DIR="${THIRD_PARTY}/mujoco-${MUJOCO_VERSION}"
if [[ ! -d "${MUJOCO_DIR}" ]]; then
  if [[ "${NETWORK_MODE}" == "cn" && -f /etc/network_turbo ]]; then
    set +u
    source /etc/network_turbo
    set -u
  fi
  curl -fL --retry 5 --retry-delay 2 \
    "https://github.com/google-deepmind/mujoco/releases/download/${MUJOCO_VERSION}/mujoco-${MUJOCO_VERSION}-linux-x86_64.tar.gz" \
    -o "${MUJOCO_ARCHIVE}"
  if [[ "${NETWORK_MODE}" == "cn" ]]; then
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY || true
  fi
  tar -xzf "${MUJOCO_ARCHIVE}" -C "${THIRD_PARTY}"
fi
ln -sfn "${MUJOCO_DIR}" "${THIRD_PARTY}/unitree_mujoco/simulate/mujoco"
cmake -S "${THIRD_PARTY}/unitree_mujoco/simulate" \
  -B "${THIRD_PARTY}/unitree_mujoco/simulate/build" \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${LOCAL_PREFIX}"
cmake --build "${THIRD_PARTY}/unitree_mujoco/simulate/build" \
  --target unitree_mujoco --parallel "$(nproc)"

echo "[9/10] Writing reusable activation and version files"
if [[ ! -f "${A2_ROOT}/activate.sh" ]]; then
  cat > "${A2_ROOT}/activate.sh" <<'ACTIVATE'
#!/usr/bin/env bash
_a2_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
unset CONDA_PREFIX CONDA_DEFAULT_ENV
source "${_a2_root}/.venv/bin/activate"
export A2_HOME="${_a2_root}"
export ISAACLAB_PATH="${_a2_root}/third_party/IsaacLab"
export UNITREE_ROS_PATH="${_a2_root}/third_party/unitree_ros"
export UNITREE_SDK2_PATH="${_a2_root}/third_party/unitree_sdk2"
export UNITREE_MUJOCO_PATH="${_a2_root}/third_party/unitree_mujoco"
export CMAKE_PREFIX_PATH="${_a2_root}/.local${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export LD_LIBRARY_PATH="${_a2_root}/.local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export OMNI_KIT_ACCEPT_EULA=YES
export PYTHONUNBUFFERED=1
echo "Unitree environment activated: ${A2_HOME}"
ACTIVATE
  chmod +x "${A2_ROOT}/activate.sh"
fi

if [[ ! -f "${A2_ROOT}/.gitignore" ]]; then
  cat > "${A2_ROOT}/.gitignore" <<'GITIGNORE'
.venv
.venv/
.venv.partial.*/
.miniconda/
.local/
.cache/
logs/
third_party/
tools/
__pycache__/
*.pyc
GITIGNORE
fi

cat > "${A2_ROOT}/VERSIONS.lock" <<VERSIONS
python=$(python --version 2>&1 | awk '{print $2}')
torch=$(python -c 'import torch; print(torch.__version__)')
isaacsim=$(python -c 'from importlib.metadata import version; print(version("isaacsim"))')
isaaclab=$(python -c 'from importlib.metadata import version; print(version("isaaclab"))')
mujoco=$(python -c 'from importlib.metadata import version; print(version("mujoco"))')
nvidia_driver=${NVIDIA_DRIVER_VERSION:-unknown}
isaac_rendering=${ISAAC_RENDERING_STATUS}
IsaacLab=$(git -C "${THIRD_PARTY}/IsaacLab" rev-parse HEAD)
unitree_ros=$(git -C "${THIRD_PARTY}/unitree_ros" rev-parse HEAD)
unitree_sdk2=$(git -C "${THIRD_PARTY}/unitree_sdk2" rev-parse HEAD)
unitree_mujoco=$(git -C "${THIRD_PARTY}/unitree_mujoco" rev-parse HEAD)
VERSIONS

if [[ ! -d "${A2_ROOT}/.git" ]]; then
  git -C "${A2_ROOT}" init -b main
fi

echo "[10/10] Running GPU, A2 model, and Isaac Sim smoke tests"
python - <<PY
from pathlib import Path
import mujoco
import torch

assert torch.cuda.is_available(), "CUDA is not available"
x = torch.rand((1024, 1024), device="cuda")
print("CUDA_OK", torch.cuda.get_device_name(0), float(x.mean()))

model_path = Path("${THIRD_PARTY}/unitree_mujoco/unitree_robots/a2/scene_terrain.xml")
model = mujoco.MjModel.from_xml_path(str(model_path))
data = mujoco.MjData(model)
for _ in range(100):
    mujoco.mj_step(model, data)
assert model.nu == 12, f"Expected 12 A2 actuators, got {model.nu}"
print("A2_MUJOCO_OK", "actuators=12", f"sim_time={data.time:.3f}s")
PY

cat > "${CACHE_DIR}/isaac_smoke.py" <<'PY'
import argparse
import os
from isaaclab.app import AppLauncher

parser = argparse.ArgumentParser()
AppLauncher.add_app_launcher_args(parser)
launcher = AppLauncher(parser.parse_args())

from isaaclab.sim import SimulationCfg, SimulationContext

sim = SimulationContext(SimulationCfg(dt=0.01, device="cuda:0"))
sim.reset()
for _ in range(10):
    sim.step(render=False)
print("ISAAC_HEADLESS_OK", flush=True)
# Isaac Sim 5.1 may block during renderer teardown without an X server.
os._exit(0)
PY

cd "${THIRD_PARTY}/IsaacLab"
timeout 180 ./isaaclab.sh -p "${CACHE_DIR}/isaac_smoke.py" --headless

git -C "${A2_ROOT}" config user.name >/dev/null 2>&1 || \
  git -C "${A2_ROOT}" config user.name "Unitree Environment Setup"
git -C "${A2_ROOT}" config user.email >/dev/null 2>&1 || \
  git -C "${A2_ROOT}" config user.email "unitree-setup@local"
git -C "${A2_ROOT}" add setup_a2_pro.sh activate.sh VERSIONS.lock .gitignore 2>/dev/null || true
if ! git -C "${A2_ROOT}" diff --cached --quiet; then
  git -C "${A2_ROOT}" commit -m "Configure reproducible Unitree simulation environment"
fi

echo
echo "Unitree environment is ready."
echo "Use it with: cd ${A2_ROOT} && source ./activate.sh"
echo "Compatible path: /workspace/a2-pro"
echo "Persistent logs: ${PERSIST_ROOT}/isaaclab_logs"
echo "A2 SDK examples: ${THIRD_PARTY}/unitree_sdk2/build/bin"
echo "A2 MuJoCo simulator: ${THIRD_PARTY}/unitree_mujoco/simulate/build/unitree_mujoco"
if [[ "${ISAAC_RENDERING_STATUS}" != "available" ]]; then
  echo "RTX rendering: unavailable with driver ${NVIDIA_DRIVER_VERSION}; do not add --video on this host."
fi
