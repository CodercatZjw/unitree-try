# syntax=docker/dockerfile:1.7
ARG ISAACLAB_IMAGE=nvcr.io/nvidia/isaac-lab:2.3.2@sha256:388dbc806f48359a964cb9f807feb226da95d0a107f470fdcad9780ea10fe6f2
FROM ${ISAACLAB_IMAGE}

LABEL org.opencontainers.image.title="unitree-try"
LABEL org.opencontainers.image.description="Reproducible Unitree A2 Pro, G1, and H1 simulation environment"
LABEL org.opencontainers.image.source="https://github.com/CodercatZjw/unitree-try"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root

ARG UNITREE_ROS_REF=7d6075f7f58588b189b940130e3edab3c839b2df
ARG UNITREE_SDK2_REF=9754cd153af3da471b0fe5f3aa535e426fb11db3
ARG UNITREE_MUJOCO_REF=4134cb5dc7ff1ba7f484deda48b5274b58694519
ARG MUJOCO_VERSION=3.3.6

ENV DEBIAN_FRONTEND=noninteractive \
    UNITREE_ROOT=/opt/unitree-runtime \
    ISAACLAB_PATH=/workspace/isaaclab \
    UNITREE_ROS_PATH=/opt/unitree-runtime/third_party/unitree_ros \
    UNITREE_SDK2_PATH=/opt/unitree-runtime/third_party/unitree_sdk2 \
    UNITREE_MUJOCO_PATH=/opt/unitree-runtime/third_party/unitree_mujoco \
    OMNI_KIT_ACCEPT_EULA=YES \
    ACCEPT_EULA=Y \
    PYTHONUNBUFFERED=1

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake ninja-build git git-lfs curl ca-certificates pkg-config \
      libeigen3-dev libyaml-cpp-dev libspdlog-dev libfmt-dev \
      libboost-program-options-dev libglfw3-dev libgl1 libglu1-mesa libegl1 \
      libx11-6 libxext6 libxi6 libxrandr2 libxinerama1 libxcursor1 \
      libxkbcommon0 libsm6 libice6 libxt6 libvulkan1 vulkan-tools ffmpeg && \
    git lfs install --system --skip-repo && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${UNITREE_ROOT}/third_party" "${UNITREE_ROOT}/.local" "${UNITREE_ROOT}/bin" && \
    clone_at_ref() { \
      local url="$1" destination="$2" ref="$3"; \
      git clone --filter=blob:none --no-checkout "${url}" "${destination}"; \
      git -C "${destination}" fetch --depth 1 origin "${ref}"; \
      git -C "${destination}" checkout --detach FETCH_HEAD; \
    }; \
    clone_at_ref https://github.com/unitreerobotics/unitree_ros.git "${UNITREE_ROS_PATH}" "${UNITREE_ROS_REF}"; \
    clone_at_ref https://github.com/unitreerobotics/unitree_sdk2.git "${UNITREE_SDK2_PATH}" "${UNITREE_SDK2_REF}"; \
    clone_at_ref https://github.com/unitreerobotics/unitree_mujoco.git "${UNITREE_MUJOCO_PATH}" "${UNITREE_MUJOCO_REF}"

COPY patches/isaaclab/0001-add-g1-running-task.patch /tmp/0001-add-g1-running-task.patch
RUN if git -C "${ISAACLAB_PATH}" apply --reverse --check /tmp/0001-add-g1-running-task.patch >/dev/null 2>&1; then \
      echo "G1 running task patch is already present"; \
    else \
      git -C "${ISAACLAB_PATH}" apply --check /tmp/0001-add-g1-running-task.patch; \
      git -C "${ISAACLAB_PATH}" apply /tmp/0001-add-g1-running-task.patch; \
    fi && \
    rm /tmp/0001-add-g1-running-task.patch

RUN --mount=type=cache,target=/root/.cache/pip \
    cd "${ISAACLAB_PATH}" && \
    ./isaaclab.sh -p -c 'import rsl_rl' && \
    ./isaaclab.sh -p -m pip install --no-cache-dir "mujoco==${MUJOCO_VERSION}"

RUN cmake -S "${UNITREE_SDK2_PATH}" -B "${UNITREE_SDK2_PATH}/build" \
      -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${UNITREE_ROOT}/.local" && \
    cmake --build "${UNITREE_SDK2_PATH}/build" --parallel "$(nproc)" && \
    cmake --install "${UNITREE_SDK2_PATH}/build"

RUN curl -fL --retry 5 --retry-delay 2 \
      "https://github.com/google-deepmind/mujoco/releases/download/${MUJOCO_VERSION}/mujoco-${MUJOCO_VERSION}-linux-x86_64.tar.gz" \
      -o /tmp/mujoco.tar.gz && \
    tar -xzf /tmp/mujoco.tar.gz -C "${UNITREE_ROOT}/third_party" && \
    rm /tmp/mujoco.tar.gz && \
    ln -sfn "${UNITREE_ROOT}/third_party/mujoco-${MUJOCO_VERSION}" "${UNITREE_MUJOCO_PATH}/simulate/mujoco" && \
    cmake -S "${UNITREE_MUJOCO_PATH}/simulate" -B "${UNITREE_MUJOCO_PATH}/simulate/build" \
      -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${UNITREE_ROOT}/.local" && \
    cmake --build "${UNITREE_MUJOCO_PATH}/simulate/build" --target unitree_mujoco --parallel "$(nproc)"

COPY docker/activate.sh ${UNITREE_ROOT}/activate.sh
COPY docker/python-wrapper.sh ${UNITREE_ROOT}/bin/python
COPY docker/entrypoint.sh ${UNITREE_ROOT}/bin/entrypoint
COPY . /workspace/unitree-try

RUN chmod +x \
      "${UNITREE_ROOT}/activate.sh" \
      "${UNITREE_ROOT}/bin/python" \
      "${UNITREE_ROOT}/bin/entrypoint" \
      /workspace/unitree-try/docker/*.sh \
      /workspace/unitree-try/scripts/*.sh \
      /workspace/unitree-try/robots/*/code/*.sh && \
    mkdir -p /workspace/unitree-artifacts/isaaclab-logs \
      /workspace/unitree-artifacts/checkpoints \
      /workspace/unitree-artifacts/videos && \
    rm -rf "${ISAACLAB_PATH}/logs" && \
    ln -s /workspace/unitree-artifacts/isaaclab-logs "${ISAACLAB_PATH}/logs" && \
    printf '%s\n' \
      'base_image=nvcr.io/nvidia/isaac-lab:2.3.2@sha256:388dbc806f48359a964cb9f807feb226da95d0a107f470fdcad9780ea10fe6f2' \
      "mujoco=${MUJOCO_VERSION}" \
      "unitree_ros=${UNITREE_ROS_REF}" \
      "unitree_sdk2=${UNITREE_SDK2_REF}" \
      "unitree_mujoco=${UNITREE_MUJOCO_REF}" \
      > "${UNITREE_ROOT}/VERSIONS.lock"

ENV ISAACSIM_VERSION=5.1.0 \
    ISAACLAB_VERSION=2.3.2 \
    PATH=/opt/unitree-runtime/bin:${PATH} \
    CMAKE_PREFIX_PATH=/opt/unitree-runtime/.local \
    LD_LIBRARY_PATH=/opt/unitree-runtime/.local/lib

WORKDIR /workspace/unitree-try
ENTRYPOINT ["/opt/unitree-runtime/bin/entrypoint"]
CMD ["bash"]
