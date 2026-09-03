# AI Agent repository rules

These instructions apply to every AI agent modifying this repository.

## Directory documentation invariant

1. Every non-hidden project directory must contain a `README.md`.
2. Creating or moving a directory requires creating or updating that directory's `README.md` in the same commit.
3. Each directory README must state the directory's purpose, allowed contents, prohibited/generated contents, important entry points, formats, and child directories.
4. When the directory tree changes, update the nearest parent README and the root README when the top-level structure changes.
5. Before committing, audit the complete tree. Exclude `.git`, generated environments, caches, build trees, logs, and ignored runtime directories from this rule.

## Robot organization

- Each model lives at `robots/<robot_id>/`.
- Use lowercase snake_case for `robot_id`.
- A robot directory must contain `README.md`, `code/`, `data/`, `checkpoints/`, and `real_world_videos/`.
- Every one of those child directories must contain `README.md`.
- Data, checkpoint, and video directories must maintain a `manifest.csv`.
- A model README must identify manufacturer, model, degrees of freedom when known, simulation backend, supported tasks, implementation status, and real-robot safety limitations.
- Shared code belongs in a documented top-level shared directory; do not silently duplicate it across models.

## Git and large files

- Keep changes in Git and make focused commits.
- Do not commit virtual environments, simulator installations, third-party repository copies, caches, logs, temporary renders, or uncurated training output.
- Large models, datasets, rosbags, and videos are opt-in. Use the existing Git LFS rules and update the corresponding manifest.
- Never force-add a large or ignored file unless the user explicitly requested that exact artifact and its provenance and privacy have been checked.

## Security and truthfulness

- Never commit credentials, tokens, private keys, host addresses, robot certificates, serial numbers, or private network configuration.
- Do not label simulation output as real-world data.
- Do not add real-world media without documented authorization and a privacy review.
- Do not claim that a policy is safe for hardware solely because it works in simulation.

## Validation

- Shell scripts must pass `bash -n`.
- Python files must compile before commit.
- Keep setup scripts repeatable and pin important dependency revisions.
- Preserve existing user data and unrelated changes.
