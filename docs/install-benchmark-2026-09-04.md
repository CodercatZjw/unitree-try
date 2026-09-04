# Native installation benchmark: 2026-09-04

This report records a clean installation with `scripts/setup_unitree_env.sh`. It intentionally omits host addresses, credentials, and provider-specific identifiers.

## Test host

- Ubuntu 24.04.4 LTS
- NVIDIA GeForce RTX 4090, 24 GB
- NVIDIA driver 580.173.02
- 96 logical CPU threads
- 50 GB writable filesystem
- No pre-existing Unitree runtime

## Result

- Overall wall time, including diagnosis and recovery from the Git LFS hook conflict: **33 minutes 10 seconds**
- Successful idempotent installer run: **31 minutes 23 seconds**
- Final runtime size: approximately **24 GB**
- Remaining disk space: approximately **27 GB**
- A2/A2 Pro MuJoCo smoke test: passed
- Isaac Lab headless CUDA/Vulkan smoke test: passed
- G1 flat, rough, and running tasks: present
- H1 flat and rough tasks: present

The initial run stopped after 30 seconds because the base image already supplied a Git LFS hook. The installer now uses `git lfs install --system --skip-repo`, which preserves image-provided hooks and makes this step repeatable.

## Successful-run stage timings

| Stage | Duration |
| --- | ---: |
| Ubuntu packages | 5 seconds |
| uv and Python 3.11 | 14 seconds |
| Isaac Sim 5.1 | 19 minutes 16 seconds |
| CUDA 12.8 PyTorch | 5 minutes 57 seconds |
| Pinned source repositories | 2 minutes 15 seconds |
| Repository patches | less than 1 second |
| Isaac Lab and RSL-RL | 2 minutes 26 seconds |
| Unitree SDK2 build | 24 seconds |
| Unitree MuJoCo build | 32 seconds |
| Activation and version lock | 2 seconds |
| Smoke tests | 12 seconds |

Isaac Sim and PyTorch downloads accounted for most of the installation time. Observed large-package download throughput was generally 5–15 MB/s. Temporary extraction raised disk use to roughly 26 GB before it settled near 24 GB.

## Recorded environment

```text
python=3.11.15
torch=2.7.0+cu128
isaacsim=5.1.0.0
isaaclab=0.54.2
mujoco=3.3.6
nvidia_driver=580.173.02
IsaacLab=37ddf626871758333d6ed89cf64ad702aef127d0
unitree_ros=7d6075f7f58588b189b940130e3edab3c839b2df
unitree_sdk2=9754cd153af3da471b0fe5f3aa535e426fb11db3
unitree_mujoco=4134cb5dc7ff1ba7f484deda48b5274b58694519
```

## Docker comparison baseline

A future Docker benchmark should use the same host class and measure from the start of the image pull through the first successful A2 MuJoCo and Isaac Lab headless smoke tests. Image pull time and first-run shader/cache warm-up should be reported separately.

### Initial Docker implementation

- Official base image: `nvcr.io/nvidia/isaac-lab:2.3.2`
- Pinned base digest: `sha256:388dbc806f48359a964cb9f807feb226da95d0a107f470fdcad9780ea10fe6f2`
- Official base expanded size: approximately 17.55 GB
- Final Unitree image expanded size: approximately 20.54 GB
- Unitree incremental build after the base pull: 8 minutes 45 seconds
- Cached rebuild after an entry-script change: about 6 seconds
- Container GPU plus A2/Isaac Lab smoke test: about 17 seconds

The first NGC pull experienced a network retry, so it is not used as a clean pull-time benchmark. A new-host comparison must still measure the image pull separately. Docker materially reduces dependency resolution and compilation time, while its total cold-start advantage depends on registry throughput and whether the cloud provider already caches the base layers.
