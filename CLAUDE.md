# Claude repository instructions

Claude and other compatible coding agents must follow these rules for every change.

## Mandatory README rule

1. Every non-hidden project directory must contain a `README.md`.
2. Never create or move a directory without adding or updating its `README.md` in the same change.
3. A directory README must explain its purpose, allowed contents, prohibited/generated contents, important entry points, file formats, and child directories.
4. Update the parent README whenever its child layout changes; update the root README for top-level or robot-layout changes.
5. Before committing, audit all project directories. Ignore `.git`, generated runtimes, virtual environments, caches, builds, logs, and other ignored output.

## Adding a robot

- Put each model in `robots/<robot_id>/`, using lowercase snake_case.
- Create `README.md`, `code/README.md`, `data/README.md`, `checkpoints/README.md`, and `real_world_videos/README.md`.
- Create a `manifest.csv` in data, checkpoints, and real-world video directories.
- Document manufacturer, model, known degrees of freedom, simulation backend, supported tasks, implementation status, and hardware safety constraints.
- Follow `docs/adding-a-robot.md`; keep shared logic in a documented shared directory.

## Repository safety

- Use Git with focused commits.
- Do not commit virtual environments, simulator installations, third-party clones, caches, logs, temporary renders, or uncurated experiment output.
- Use Git LFS and manifests for intentionally versioned large artifacts.
- Never force-add ignored artifacts without explicit user authorization and a provenance/privacy review.
- Never commit secrets, access tokens, private keys, cloud host details, robot credentials, serial numbers, or private network information.
- Never describe simulation footage as real-world footage.
- Simulation success is not proof of safe real-robot deployment.

## Checks before commit

- Run `bash -n` for changed Shell scripts.
- Compile changed Python files.
- Confirm every applicable directory has a README.
- Confirm manifests and parent indexes match the filesystem.
- Preserve user data and unrelated work.
