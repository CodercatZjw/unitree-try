# 框架与算法学习路线

## 这个项目实际运行了什么

G1 和 H1 的行走训练使用 Isaac Lab 的 manager-based velocity tracking 环境，通过 RSL-RL 运行 PPO。策略网络读取机身速度、角速度、重力方向、目标速度、关节位置、关节速度和上一时刻动作，输出各关节的位置目标。

PPO 训练的是 Actor-Critic：

- Actor 根据观测产生动作。
- Critic 估计状态价值。
- GAE 根据采样轨迹计算优势。
- PPO clipped objective 限制一次更新幅度，减少策略突然崩坏。
- 1024 个并行环境在 GPU 上同时采样，提高吞吐量。

G1 奔跑任务从行走检查点继续训练，把前进指令提升到 1.0--2.5 m/s，并加入速度跟踪、直立姿态、腾空相位、防滑、动作平滑、关节限位和摔倒惩罚。第一版能够学习稳定高速移动，但自然跑姿仍需要分阶段速度课程和更明确的周期步态约束。

A2/A2 Pro 当前只验证了 MuJoCo 模型、执行器和物理仿真，没有声称已经训练出可部署的强化学习策略。

## 建议掌握的框架

1. **Python 与 NumPy**：数组、类、配置、日志和实验脚本。
2. **PyTorch**：张量、自动微分、神经网络、优化器和 GPU。
3. **Gymnasium**：环境、观测空间、动作空间、reset 和 step。
4. **Isaac Sim**：USD 场景、PhysX、传感器、GPU 仿真和离屏渲染。
5. **Isaac Lab**：机器人资产、ManagerBasedRLEnv、观测项、奖励项、终止条件和随机化。
6. **RSL-RL**：PPO 配置、并行 rollout、checkpoint、play 和策略导出。
7. **MuJoCo**：模型 XML、关节、执行器、接触和快速动力学验证。
8. **Unitree SDK2 与 CycloneDDS**：真机状态订阅、命令发布和通信域。
9. **ROS 2**：消息、节点、TF、传感器和上层导航；不是训练 PPO 的必需项，但对系统集成有用。
10. **Git 与 Git LFS**：代码、补丁、实验清单和大文件版本管理。

## 必须理解的算法知识

### 强化学习基础

- 马尔可夫决策过程：状态、观测、动作、转移、奖励和折扣。
- on-policy 与 off-policy 的差别。
- policy gradient、Actor-Critic、价值函数和优势函数。
- PPO clipping、entropy、learning rate、batch 和 epoch。
- GAE 中 gamma 与 lambda 的作用。

### 机器人控制

- 刚体动力学、正向与逆向运动学。
- PD 控制、关节位置控制、扭矩控制。
- 质心、支撑多边形、接触力和摩擦锥。
- 双足步态中的单支撑、双支撑、腾空和落地冲击。
- 状态估计、IMU、编码器和延迟。

### 训练工程

- reward shaping 与奖励投机。
- observation/action normalization。
- curriculum learning。
- domain randomization 和 system identification。
- 并行环境、采样效率和收敛曲线。
- 独立的 deterministic evaluation，不能只看带探索噪声的训练视频。
- ablation、随机种子和可重复实验。

### 仿真到真机

- 质量、惯量、摩擦、电机强度和延迟随机化。
- 动作限幅、低通滤波和策略运行频率。
- 通信丢包与超时处理。
- 吊装、急停、低速、软地面到正常地面的递进测试。

## 推荐学习顺序

1. 用 MuJoCo 理解关节、执行器和接触。
2. 用 Gymnasium 写一个简单控制环境。
3. 学会 PyTorch Actor-Critic 和 PPO。
4. 跑通 Isaac Lab 的现成 G1/H1 平地任务。
5. 修改一个奖励项并比较训练曲线。
6. 加入崎岖地形和课程学习。
7. 做固定命令、无噪声的独立评估。
8. 加入域随机化，再考虑真机部署。
