# AutoDL 上配置 Unitree A2/A2 Pro、G1、H1 仿真环境

## 1. 目标与验证结果

本文记录 2026-09-04 在一台 AutoDL RTX 4090 24 GB 实例上的完整部署过程。最终环境通过了以下实跑检查：

- PyTorch 能在 RTX 4090 上创建并计算 CUDA 张量；
- Unitree A2 MuJoCo 模型成功载入，识别 12 个执行器并完成物理步进；
- Isaac Sim 5.1 使用 Vulkan 在无显示器模式启动；
- Isaac Lab 的 G1 平地速度跟踪任务完成 1,500 轮 PPO 训练；
- 训练过程可生成 H.264、1280×720、50 FPS 的阶段视频。

本次验证的核心版本：

| 组件 | 版本或提交 |
|---|---|
| Ubuntu | 22.04.5 LTS |
| NVIDIA 驱动 | 580.105.08 |
| Python | 3.11.16 |
| PyTorch | 2.7.0+cu126 |
| Isaac Sim | 5.1.0.0 |
| Isaac Lab | v2.3.2，`37ddf626871758333d6ed89cf64ad702aef127d0` |
| MuJoCo Python | 3.3.6 |
| Unitree ROS | `7d6075f7f58588b189b940130e3edab3c839b2df` |
| Unitree SDK2 | `9754cd153af3da471b0fe5f3aa535e426fb11db3` |
| Unitree MuJoCo | `4134cb5dc7ff1ba7f484deda48b5274b58694519` |

## 2. 为什么这样规划目录

默认目录如下：

| 内容 | 路径 | 存储类型 |
|---|---|---|
| Python、Isaac Sim、Isaac Lab、Unitree 源码与编译结果 | `/root/autodl-tmp/a2-pro` | AutoDL 本地高速数据盘 |
| 兼容入口 | `/workspace/a2-pro` | 指向上述目录的软链接 |
| 训练日志、检查点、视频 | `/root/autodl-fs/a2-data/isaaclab_logs` | AutoDL 文件存储 |
| 安装脚本备份 | `/root/autodl-fs/a2-data/setup_a2_pro_cn.sh` | AutoDL 文件存储 |

完整运行环境约占 25 GB。建议数据盘至少 50 GB，并在首次安装前保留 35 GB 以上可用空间。

这样安排的目的，是让高频读写发生在本地 SSD，而训练成果进入更适合长期保留的文件存储。

### 保存 AutoDL 镜像时的重要限制

AutoDL 的“保存镜像”只保存系统盘。`/root/autodl-tmp` 是数据盘，因此默认安装在其中的完整环境不会进入镜像；`/workspace/a2-pro` 只是软链接，保存它并不等于保存链接指向的环境。

`/root/autodl-fs` 也不属于镜像，但它是独立文件存储：同地区新实例通常可以重新挂载并继续使用其中的日志、模型和脚本。迁移完整环境时，应选择克隆/复制数据盘，或者扩容系统盘后将环境重新安装到系统盘路径。

## 3. 一键安装

在 AutoDL 实例中执行：

```bash
git clone https://github.com/CodercatZjw/unitree-try.git
cd unitree-try
chmod +x ./一键配置.sh
NETWORK_MODE=cn bash ./一键配置.sh
```

脚本需要 root 权限，支持重复执行和断点续装。大文件下载或 SSH 中断后，直接重新执行同一条命令即可。

安装完成后激活环境：

```bash
cd /root/autodl-tmp/a2-pro
source ./activate.sh
cat ./VERSIONS.lock
```

如果要改变位置，可以在首次安装时指定：

```bash
A2_ROOT=/root/autodl-tmp/a2-pro \
PERSIST_ROOT=/root/autodl-fs/a2-data \
NETWORK_MODE=cn \
bash ./一键配置.sh
```

## 4. 网络模式

脚本提供两个互斥模式，不能在同一次运行中混用。

### 国内模式（默认）

```bash
NETWORK_MODE=cn bash ./一键配置.sh
```

使用：

- AutoDL 镜像现有的华为云 Ubuntu APT 源；
- 清华大学 Miniconda 镜像；
- 阿里云 PyPI 与 PyTorch 镜像；
- NVIDIA 中国 Python 包源；
- `/etc/network_turbo`，仅在访问 GitHub 和 GitHub Release 时临时启用。

国内模式会主动清除所有代理环境变量。

### 本地 Clash + 官方源模式

首先在服务器本机准备 HTTP 代理，并确认监听 `127.0.0.1:7890`。然后执行：

```bash
NETWORK_MODE=proxy \
CLASH_PROXY=http://127.0.0.1:7890 \
bash ./一键配置.sh
```

该模式使用官方 PyPI、NVIDIA PyPI、PyTorch 和 GitHub。脚本仍会在 APT 阶段关闭代理，完成国内 APT 操作后才启用代理。不要把 Clash 订阅或节点凭据提交到本仓库。

## 5. 脚本做了什么

脚本按顺序完成以下工作：

1. 安装编译工具、Vulkan/OpenGL、FFmpeg、Git LFS、tmux 等系统依赖；
2. 在项目目录安装固定的 Python 3.11 Miniconda；
3. 安装 Isaac Sim 5.1 及扩展缓存；
4. 验证 PyTorch 2.7 能访问 GPU，避免重复下载数 GB CUDA 运行库；
5. 按提交哈希获取 Isaac Lab、Unitree ROS、SDK2 和 MuJoCo；
6. 安装 Isaac Lab 与 RSL-RL；
7. 编译安装 Unitree SDK2；
8. 下载 MuJoCo 3.3.6 并编译官方 Unitree MuJoCo DDS 模拟器；
9. 写入 `activate.sh` 与 `VERSIONS.lock`；
10. 运行 CUDA、A2 MuJoCo 和 Isaac Sim 无界面自检。

## 6. 运行 A2/A2 Pro

先激活环境：

```bash
cd /root/autodl-tmp/a2-pro
source ./activate.sh
```

仅验证 A2 模型和物理步进不需要桌面，安装脚本末尾已经自动完成。需要打开官方 Unitree MuJoCo 图形模拟器时：

```bash
cd "$UNITREE_MUJOCO_PATH/simulate"
./build/unitree_mujoco -r unitree_robots/a2/scene_terrain.xml
```

云主机没有桌面时，需要先配置 AutoDL 远程桌面或可用的 X11/VNC 会话。

## 7. 训练 G1 或 H1 行走

### G1 平地行走

```bash
source /root/autodl-tmp/a2-pro/activate.sh
cd "$ISAACLAB_PATH"

./isaaclab.sh -p scripts/reinforcement_learning/rsl_rl/train.py \
  --task Isaac-Velocity-Flat-G1-v0 \
  --num_envs 1024 \
  --max_iterations 1500 \
  --headless \
  --video \
  --video_interval 5000 \
  --video_length 300 \
  --run_name g1_walk_periodic_video
```

### H1 平地行走

将任务名替换为：

```text
Isaac-Velocity-Flat-H1-v0
```

### 后台运行

长时间训练建议放进 tmux：

```bash
tmux new-session -s g1-walk
# 在 tmux 内执行训练命令
```

按 `Ctrl+B`，再按 `D` 退出但不停止训练；重新连接后执行：

```bash
tmux attach -t g1-walk
```

检查点和视频位于：

```text
/root/autodl-fs/a2-data/isaaclab_logs/rsl_rl/g1_flat/<运行目录>/
```

本次 1,024 环境、1,500 轮训练在 RTX 4090 上用时约 38 分钟（RSL-RL 报告的纯训练时间约 2,278 秒），最终保存为 `model_1499.pt`。

## 8. 常见问题

### 为什么 GPU、显存和内存没有吃满

这是正常现象。强化学习会交替执行 PhysX 仿真、CPU 环境逻辑、GPU 策略更新和视频渲染。G1 的策略网络较小，1,024 个环境通常只使用约 6.7 GB 显存，GPU 使用率会呈现锯齿状。应以每秒样本数、单轮耗时和奖励曲线为准，而不是以显存占满为目标。

下一轮可尝试把 `--num_envs` 提高到 2,048，再视显存和吞吐尝试 4,096。为了最大化训练吞吐，也可以在主训练中关闭视频，训练后单独加载检查点录制。

### Isaac Sim 在启动时段错误

先查看驱动：

```bash
nvidia-smi
```

本项目实际验证 NVIDIA 580.105.08 可运行 Isaac Sim 5.1 Vulkan 渲染。此前另一台使用 595 系列驱动的主机在 RTX 渲染阶段出现过 `librtx.scenedb.plugin.so` 段错误；脚本检测到 595 系列时会给出警告。此时应更换驱动兼容的主机，或者成套升级 Isaac Sim 与 Isaac Lab，不要只替换其中一个组件。

### 安装中断

重新执行同一条安装命令。脚本会复用 Miniconda、Pip 缓存、Git 仓库和已经完成的编译结果。

### 磁盘空间不足

检查：

```bash
df -h / /root/autodl-tmp /root/autodl-fs
du -sh /root/autodl-tmp/a2-pro
```

不要删除 `/root/autodl-fs/a2-data/isaaclab_logs` 中仍需保留的模型。确认不再需要后，可以清理 `/root/autodl-tmp/a2-pro/.cache` 中的下载缓存。

## 9. 安全提示

- 真机部署前必须先完成仿真评估；
- 低层控制测试时保证机器人架空、急停可用，并核对关节限位；
- 不要把 Clash 订阅、SSH 私钥、访问令牌或机器人凭据提交到 Git；
- `/root/autodl-tmp` 是本地数据盘，没有冗余保证；重要模型应另外备份。
