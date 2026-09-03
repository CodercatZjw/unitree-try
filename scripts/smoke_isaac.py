import argparse
import os

from isaaclab.app import AppLauncher

parser = argparse.ArgumentParser()
AppLauncher.add_app_launcher_args(parser)
launcher = AppLauncher(parser.parse_args())

from isaaclab.sim import SimulationCfg, SimulationContext

sim = SimulationContext(SimulationCfg(dt=0.01, device="cuda:0"))
sim.reset()
for _ in range(10):
    sim.step(render=False)
print("ISAAC_HEADLESS_OK", flush=True)
os._exit(0)
