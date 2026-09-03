# 环境与复现说明

## 固定版本

| 组件 | 版本或提交 |
|---|---|
| Python | 3.11 |
| PyTorch | 2.7.0 + CUDA 12.8 |
| Isaac Sim | 5.1.0 |
| Isaac Lab | 2.3.2 / `37ddf626871758333d6ed89cf64ad702aef127d0` |
| MuJoCo | 3.3.6 |
| unitree_ros | `7d6075f7f58588b189b940130e3edab3c839b2df` |
| unitree_sdk2 | `9754cd153af3da471b0fe5f3aa535e426fb11db3` |
| unitree_mujoco | `4134cb5dc7ff1ba7f484deda48b5274b58694519` |

一键脚本会生成 `VERSIONS.lock`，记录实际安装版本、源码提交和宿主机 NVIDIA 驱动。

## 为什么把运行时放在仓库外

Isaac Sim 和相关缓存体积很大，而且包含机器相关文件。默认运行时目录是 `/workspace/unitree-runtime`，Git 仓库保持轻量。删除运行时后重新执行安装脚本即可重建。

## 驱动兼容

这套已验证组合使用 Isaac Sim 5.1 和 NVIDIA 580 系列驱动。595 系列驱动曾在 RTX 渲染初始化时出现段错误；脚本检测到该分支会发出警告。容器内通常不能更换宿主机驱动。

## 可重复执行

安装脚本会：

1. 安装 Ubuntu 编译和图形运行库。
2. 使用 uv 准备 Python 3.11 虚拟环境。
3. 安装固定版本的 Isaac Sim、PyTorch 和 MuJoCo。
4. 下载固定提交的 Isaac Lab 与 Unitree 仓库。
5. 应用本仓库维护的 Isaac Lab 补丁。
6. 编译 Unitree SDK2 和 Unitree MuJoCo。
7. 运行 CUDA、Isaac Lab 和 A2 MuJoCo 冒烟测试。

如果只想恢复安装而暂时跳过测试：

```bash
sudo -E SKIP_SMOKE_TESTS=1 bash scripts/setup_unitree_env.sh
```

## 诊断

```bash
UNITREE_ROOT=/workspace/unitree-runtime ./scripts/doctor.sh
```

不要在问题报告中粘贴 SSH 私钥、访问令牌、机器人序列号或包含真实现场网络信息的配置。
