# Unitree G1

## 已配置任务

| 模式 | Isaac Lab 任务 | 默认录像间隔 |
|---|---|---:|
| 平地行走 | `Isaac-Velocity-Flat-G1-v0` | 5000 控制步 |
| 崎岖地形 | `Isaac-Velocity-Rough-G1-v0` | 5000 控制步 |
| 高速奔跑 | `Isaac-Velocity-Run-G1-v0` | 2500 控制步 |

运行：

```bash
robots/g1/code/train_locomotion.sh walk
robots/g1/code/train_locomotion.sh rough
robots/g1/code/train_locomotion.sh run
```

常用参数：

```bash
NUM_ENVS=1024 MAX_ITERATIONS=1500 VIDEO_INTERVAL=5000 \
  robots/g1/code/train_locomotion.sh walk
```

继续训练：

```bash
RESUME=1 LOAD_RUN='<运行目录名>' CHECKPOINT='model_1500.pt' \
  robots/g1/code/train_locomotion.sh walk
```

训练视频是带探索噪声和随机命令的过程记录。判断策略质量时，应额外使用单环境、固定命令、关闭探索噪声的 play 评估。
