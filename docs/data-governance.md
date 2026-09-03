# 数据和隐私规范

## 默认原则

- 原始数据、检查点和视频默认被 `.gitignore` 排除。
- README 和 manifest 保存在 Git 中。
- 明确需要版本化的大文件通过 Git LFS 提交。
- 大型数据集优先放对象存储，manifest 记录 URI、SHA-256、大小、采集日期和许可。

## 禁止提交

- SSH 私钥、GitHub token、云服务密钥和密码。
- 包含公网主机、内网拓扑或机器人现场凭据的配置。
- 未获得许可的人脸、声音、车牌或客户现场画面。
- 机器人序列号、设备证书和生产网络配置。
- Isaac Sim、虚拟环境、第三方仓库副本、缓存和完整训练日志。

## 真机视频

每条视频至少在 `manifest.csv` 中记录：

- 文件名
- 机型
- 场景和任务
- 采集日期
- 时长
- SHA-256
- 授权状态
- 备注

上传前检查背景、人员、屏幕和音频中是否存在敏感信息。

## 添加一个经过确认的大文件

```bash
git lfs install
git add -f robots/g1/real_world_videos/example.mp4
git add robots/g1/real_world_videos/manifest.csv
git commit -m "Add authorized G1 real-world running video"
```
