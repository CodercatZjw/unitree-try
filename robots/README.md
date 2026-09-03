# Robot models

Each child directory represents one robot model and uses lowercase snake_case.

## Current models

| ID | Manufacturer | Model | Current backend and status |
|---|---|---|---|
| `a2_pro` | Unitree | A2 / A2 Pro | MuJoCo model and SDK environment validated |
| `g1` | Unitree | G1 | Isaac Lab flat, rough, and custom running tasks |
| `h1` | Unitree | H1 | Isaac Lab flat and rough locomotion tasks |

New models must follow `docs/adding-a-robot.md` and include documented `code`, `data`, `checkpoints`, and `real_world_videos` directories.

Do not place loose files directly in this directory.
