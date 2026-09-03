# Adding a robot

## 1. Choose an identifier

Create `robots/<robot_id>/` using lowercase snake_case. Prefer a stable model name, adding the manufacturer only when needed to avoid ambiguity.

## 2. Create the complete layout

```text
robots/<robot_id>/
├── README.md
├── code/
│   └── README.md
├── data/
│   ├── README.md
│   └── manifest.csv
├── checkpoints/
│   ├── README.md
│   └── manifest.csv
└── real_world_videos/
    ├── README.md
    └── manifest.csv
```

Do not create an undocumented directory. If additional folders such as `assets/`, `configs/`, or `deployment/` are needed, each must also contain a README and be added to the model README.

## 3. Document the model

The model README should record:

- manufacturer and exact model;
- known degrees of freedom and actuator interface;
- available URDF, MJCF, USD, meshes, and license;
- supported simulators;
- implemented training and evaluation tasks;
- current validation status;
- expected hardware, driver, and memory requirements;
- real-robot deployment limitations and safety measures.

## 4. Add code without vendoring runtimes

Keep launchers, task configuration, small patches, tests, and deployment code in `code/` or a documented shared directory. Do not copy complete third-party repositories, simulator installations, virtual environments, build products, or caches.

Pin upstream repositories by URL and commit. Put maintainable source changes in `patches/` when appropriate.

## 5. Manage artifacts

- Keep ordinary Git focused on source, configuration, documentation, and manifests.
- Use Git LFS only for intentionally selected models, videos, rosbags, and datasets.
- Use object storage for large datasets and record URI plus SHA-256 in the manifest.
- Do not upload real-world media until authorization and privacy checks are documented.

## 6. Validate

- Verify changed Shell and Python files.
- Run a model-loading smoke test.
- Run a minimal training iteration when an RL task is added.
- Verify deterministic evaluation separately from noisy training videos.
- Audit every non-hidden, non-generated directory for `README.md`.
- Update `robots/README.md` and the root README.
