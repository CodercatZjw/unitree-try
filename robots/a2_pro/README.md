# Unitree A2 / A2 Pro

当前仓库接入的是 Unitree 官方 MuJoCo A2 模型和 SDK2。

启动交互仿真：

```bash
robots/a2_pro/code/run_mujoco.sh
```

云主机没有桌面显示时，先做无界面模型验证：

```bash
UNITREE_ROOT=/workspace/unitree-runtime \
  /workspace/unitree-runtime/.venv/bin/python scripts/smoke_mujoco.py
```

目前没有把 A2 声称为已完成强化学习训练。要训练 A2，需要先把 A2 资产、接触传感器、动作控制、奖励和终止条件注册为 Isaac Lab 或 MuJoCo RL 环境。
