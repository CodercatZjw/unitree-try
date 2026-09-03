# Isaac Lab patches

Patches in this directory target the Isaac Lab revision pinned by `scripts/setup_unitree_env.sh`. The installer applies them in filename order and skips patches that are already present.

- `0001-add-g1-running-task.patch`: registers the custom G1 high-speed running task and reward configuration.

When updating the Isaac Lab pin, verify every patch with `git apply --check`, run a minimal environment startup, and update this README.
