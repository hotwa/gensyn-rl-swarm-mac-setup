# 🧠 Gensyn RL-Swarm Mac 安装脚本
本脚本用于自动部署 [Gensyn 官方 rl-swarm 项目](https://github.com/gensyn-ai/rl-swarm)，简化在 macOS 上的安装流程。

这是一个适用于 Apple Silicon（M1/M2/M4）与 Intel 架构的 macOS 自动部署脚本，用于快速安装并运行 [Gensyn](https://github.com/gensyn-ai/rl-swarm) 的 `rl-swarm` 项目。

---

## 🚀 一键安装（推荐 ✅）

打开终端，复制粘贴以下命令，自动完成全部依赖安装和环境配置：

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/essenwo/gensyn-rl-swarm-mac-setup/main/setup_rl_swarm_mac.sh)"

⏱️ 安装过程会根据你的网络和设备环境耗时 5-15 分钟不等。

⸻

📦 脚本功能
	•	自动检测 Mac 架构（Apple Silicon 或 Intel）
	•	自动安装 Homebrew、Python3、Node.js、Yarn
	•	设置 Python 虚拟环境
	•	自动安装所有 Python & Node 项目的依赖包
	•	克隆 Gensyn 官方仓库 rl-swarm
	•	设置 PyTorch 相关环境变量
	•	启动执行训练脚本 run_rl_swarm.sh

⸻

✅ 支持平台

架构	是否支持
Apple Silicon (M1/M2/M4)	✅ 支持
Intel x86_64	✅ 支持
macOS Ventura、Sonoma	✅ 已测试



⸻

🧙 其他说明
	•	若安装过程中遇到 npm 权限报错，脚本会自动修复。
	•	支持多次运行，已安装部分将跳过。
	•	脚本默认使用 venv 创建虚拟环境名为 rl_env，你可自行修改。



如果这个项目帮到了你，欢迎点个 ⭐️ 或 提交 PR！



