# Unitree H1

H1 在当前 Isaac Lab 环境中提供平地和崎岖地形速度跟踪任务。

```bash
robots/h1/code/train_locomotion.sh flat
robots/h1/code/train_locomotion.sh rough
```

默认使用 1024 个并行环境、每 5000 个仿真控制步录制 300 帧。显存不足时先降低 `NUM_ENVS`。

继续训练：

```bash
RESUME=1 LOAD_RUN='<运行目录名>' CHECKPOINT='model_1500.pt' \
  robots/h1/code/train_locomotion.sh flat
```
