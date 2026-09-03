from pathlib import Path
import os

import mujoco

root = Path(os.environ.get("UNITREE_ROOT", "/workspace/unitree-runtime"))
model_path = root / "third_party/unitree_mujoco/unitree_robots/a2/scene_terrain.xml"
model = mujoco.MjModel.from_xml_path(str(model_path))
data = mujoco.MjData(model)
for _ in range(100):
    mujoco.mj_step(model, data)
assert model.nu == 12, f"expected 12 A2 actuators, got {model.nu}"
print("A2_MUJOCO_OK", f"actuators={model.nu}", f"sim_time={data.time:.3f}s")
