# unitree-try

面向多种机器人的仿真、强化学习、控制代码与真机数据工作区。仓库目前从宇树 A2/A2 Pro、G1、H1 起步，后续可以继续加入其他厂商的双足、人形、四足、机械臂及移动机器人。

这个仓库只保存可复现的代码、配置、补丁、说明和数据清单。Isaac Sim、Python 虚拟环境、第三方源码、训练日志、检查点和视频二进制默认不进入普通 Git 历史。

## 当前状态

- A2/A2 Pro：Unitree MuJoCo 模型加载与物理仿真已验证。
- G1：Isaac Lab 平地行走、崎岖地形行走可用。
- G1：自定义高速奔跑任务可用，采用 PPO 并增加受速度与直立姿态约束的腾空奖励。
- H1：Isaac Lab 平地与崎岖地形训练任务可用。
- 仿真平台：Isaac Sim 5.1.0、Isaac Lab 2.3.2、MuJoCo 3.3.6。

## 目录

```text
unitree-try/
├── AGENTS.md                   # 通用 AI Agent 维护规则
├── CLAUDE.md                   # Claude 及兼容 Agent 维护规则
├── scripts/                    # 一键安装、激活和环境诊断
├── patches/isaaclab/           # 仓库维护的 Isaac Lab 任务补丁
├── docs/                       # 环境、算法和学习路线
└── robots/
    ├── a2_pro/
    │   ├── code/
    │   ├── data/
    │   ├── checkpoints/
    │   └── real_world_videos/
    ├── g1/
    │   ├── code/
    │   ├── data/
    │   ├── checkpoints/
    │   └── real_world_videos/
    └── h1/
        ├── code/
        ├── data/
        ├── checkpoints/
        └── real_world_videos/
```

所有非隐藏子目录都必须包含自己的 `README.md`，说明目录用途、允许存放的内容和主要入口。该约束同时写入了 `AGENTS.md` 与 `CLAUDE.md`，供后续 AI Agent 自动遵守。

## 添加其他机器人

新机型使用 `robots/<robot_id>/`，其中 `robot_id` 使用小写 snake_case，例如 `atlas`、`go2` 或 `franka_panda`。标准结构为：

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

机型 README 必须写明厂商、型号、自由度、仿真后端、当前完成状态、可运行任务和真机安全限制。完整步骤见 [新增机器人指南](docs/adding-a-robot.md)。

## 一键配置

要求：

- Ubuntu 22.04 或 24.04
- NVIDIA GPU
- 建议使用 580 系列 Linux 驱动运行 Isaac Sim 5.1 RTX 录像
- 至少 30 GB 可用磁盘空间
- root 或 sudo 权限

```bash
git clone https://github.com/CodercatZjw/unitree-try.git
cd unitree-try
sudo -E bash scripts/setup_unitree_env.sh
```

默认安装到 `/workspace/unitree-runtime`。可以修改位置：

```bash
sudo -E UNITREE_ROOT=/opt/unitree-runtime bash scripts/setup_unitree_env.sh
```

安装脚本可重复执行，会复用已经完成的下载和编译结果。运行脚本表示接受 NVIDIA Isaac Sim 的相应许可条款。

安装完成后：

```bash
source /workspace/unitree-runtime/activate.sh
UNITREE_ROOT=/workspace/unitree-runtime ./scripts/doctor.sh
```

## 开始训练

G1 平地行走：

```bash
robots/g1/code/train_locomotion.sh walk
```

G1 奔跑，每 2,500 个仿真控制步录制一次：

```bash
VIDEO_INTERVAL=2500 robots/g1/code/train_locomotion.sh run
```

H1 平地行走：

```bash
robots/h1/code/train_locomotion.sh flat
```

A2/A2 Pro MuJoCo：

```bash
robots/a2_pro/code/run_mujoco.sh
```

详细参数和继续训练方式请查看各机型目录中的 README。

## 数据与模型管理

数据、检查点和真机视频目录已经建立，但默认忽略二进制内容，防止误传：

- 数据清单和说明可以直接提交。
- 确认可以公开、且确实需要版本化的文件，使用 `git add -f <file>` 明确加入。
- 视频、模型和机器人数据类型已配置 Git LFS。
- 包含人脸、地址、网络配置、机器人序列号、密钥或客户现场信息的视频不得上传。
- 大规模原始数据建议保存在对象存储，Git 中只维护 manifest、校验值和下载位置。

当前没有可确认来源和授权的真机视频，因此仓库只提交目录、数据规范与空 manifest，不会把仿真录像伪装成真机数据。

## 安全提示

仿真策略不能直接视为真机安全策略。部署前至少需要完成系统辨识、域随机化、关节限位、扭矩限制、通信超时、急停、吊装测试和低速测试。

## 文档

- [环境与复现说明](docs/environment.md)
- [算法与框架学习路线](docs/learning-roadmap.md)
- [数据和隐私规范](docs/data-governance.md)
- [新增机器人指南](docs/adding-a-robot.md)
