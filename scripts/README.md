# Scripts

Project-wide environment and validation utilities:

- `setup_unitree_env.sh`: repeatable Ubuntu/NVIDIA environment installer.
- `activate.sh`: template installed into the external runtime directory.
- `doctor.sh`: versions, GPU, source revision, and robot asset checks.
- `smoke_isaac.py`: minimal CUDA Isaac Lab simulation test.
- `smoke_mujoco.py`: minimal A2 MuJoCo model and actuator test.

Robot-specific training and deployment entry points belong under `robots/<robot_id>/code/`. Do not put generated logs, caches, environments, or downloaded dependencies here.
