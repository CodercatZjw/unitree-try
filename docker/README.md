# Docker environment

This directory builds a headless Unitree simulation image on top of the official `nvcr.io/nvidia/isaac-lab:2.3.2` image. It adds the pinned Unitree repositories, SDK2, MuJoCo 3.3.6, the repository-maintained G1 running task, and the project source.

The image is intended for Linux amd64 hosts with an NVIDIA GPU, Docker Engine 26 or newer, Docker Compose 2.25 or newer, and NVIDIA Container Toolkit. The host NVIDIA driver is not included in the image. The validated driver branch for Isaac Sim 5.1 rendering is 580.

Running the image indicates acceptance of the NVIDIA Isaac Sim/Omniverse license. `PRIVACY_CONSENT` is deliberately not enabled by default.

## Build and start

```bash
docker compose -f docker/compose.yaml build unitree
docker compose -f docker/compose.yaml up -d unitree
docker compose -f docker/compose.yaml exec unitree bash docker/smoke.sh
docker compose -f docker/compose.yaml exec unitree bash
```

The Compose development service bind-mounts the repository, so code edits on the host are immediately visible. The image also contains a source snapshot for environments such as Vast.ai where Compose is not used.

## Train

```bash
docker compose -f docker/compose.yaml exec unitree bash robots/g1/code/train_locomotion.sh walk
docker compose -f docker/compose.yaml exec unitree bash robots/g1/code/train_locomotion.sh run
docker compose -f docker/compose.yaml exec unitree bash robots/h1/code/train_locomotion.sh flat
```

G1 running records every 2,500 simulation control steps by default. Isaac Lab logs, checkpoints, and videos are written below `/workspace/unitree-artifacts/isaaclab-logs` through the `unitree-artifacts` volume.

## Persist and back up artifacts

The `unitree-artifacts` named volume is authoritative. Isaac shader and download caches use separate disposable volumes. To copy training artifacts to the host while the service is running:

```bash
mkdir -p backups/unitree-artifacts
docker compose -f docker/compose.yaml cp unitree:/workspace/unitree-artifacts/. backups/unitree-artifacts/
```

Do not add the copied checkpoints, logs, or videos to normal Git history. Store them in private object storage or an encrypted backup and update the appropriate manifest when a curated artifact is published.

## Publish a private image

```bash
docker login ghcr.io
docker buildx build --platform linux/amd64 \
  -f docker/Dockerfile \
  -t ghcr.io/codercatzjw/unitree-try:isaaclab-2.3.2 \
  --push .
```

Keep the package private. Never put registry credentials in this repository or in the image. On Vast.ai, select the published image when creating the instance and supply private registry credentials through the provider UI. Do not attempt Docker-in-Docker inside a normal Vast container.

For continued training, attach a persistent volume at `/workspace/unitree-artifacts`. Allocate at least 50 GB for the image/runtime and preferably 80 GB or more when retaining training videos and checkpoints.

Use Vast's **SSH** or **Jupyter + SSH** launch mode. Vast replaces an image's entrypoint in those modes, so set this exact on-start command in the template:

```bash
bash /workspace/unitree-try/docker/vast-onstart.sh
```

Also set `ACCEPT_EULA=Y` and `OMNI_KIT_ACCEPT_EULA=YES` in the template environment. After connecting, run `bash /workspace/unitree-try/docker/smoke.sh`. The on-start script creates the writable artifact directories and activates the Unitree environment for later login shells; it does not start training automatically.

## Files

- `Dockerfile`: reproducible image build.
- `compose.yaml`: GPU, networking, cache, and artifact volumes.
- `entrypoint.sh`: initializes writable artifact directories.
- `activate.sh`: container-specific Unitree environment activation.
- `python-wrapper.sh`: routes `python` through Isaac Lab's interpreter.
- `smoke.sh`: A2 MuJoCo and Isaac Lab CUDA/Vulkan validation.
- `vast-onstart.sh`: restores activation and artifact directories when Vast replaces the image entrypoint.

Only Docker definitions, small entry scripts, and their documentation belong in this directory. Do not store registry credentials, `.env` files, image archives, caches, logs, checkpoints, datasets, or videos here. YAML, Dockerfile, Markdown, and POSIX shell are the expected formats. This directory currently has no child directories; create a documented child directory only when several related Docker assets genuinely need one.
