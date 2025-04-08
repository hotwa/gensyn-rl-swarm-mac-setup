#!/bin/bash

set -e

echo "=== Gensyn RL-Swarm 通用安装脚本 for macOS Intel & Apple Silicon ==="

# 检查架构
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "✔ 当前为 Apple Silicon (arm64 架构)"
    BREW_PREFIX="/opt/homebrew"
else
    echo "✔ 当前为 Intel (x86_64 架构)"
    BREW_PREFIX="/usr/local"
fi

# 加载 brew 环境
if ! command -v brew &>/dev/null; then
    echo "⚠️ 未检测到 Homebrew，开始安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "🔧 加载 Homebrew 环境变量..."
eval "$($BREW_PREFIX/bin/brew shellenv)"

echo "🚀 禁用代理"
unset http_proxy https_proxy all_proxy

echo "📥 克隆 rl-swarm 项目"
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm

echo "🐍 安装 Python 和 Node.js"
brew install python node

echo "🧪 创建并激活 Python 虚拟环境"
python3 -m venv rl_env
source rl_env/bin/activate

echo "🔁 建立 python 软链接指向 python3"
sudo ln -sf "$(which python3)" /usr/local/bin/python

echo "🐍 安装 Python 依赖包..."
pip install -r requirements.txt
pip install -r requirements-hivemind.txt
pip install colorlog torch transformers datasets accelerate peft trl wandb hivemind bitsandbytes safetensors

echo "🧠 设置 PyTorch MPS（Metal 后端）内存环境变量"
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

echo "🧵 安装 Yarn"
npm install -g yarn

echo "🛠 检查并修复 npm 权限问题"
sudo chown -R "$(id -u):$(id -g)" ~/.npm || true

echo "📦 安装 modal-login 前端依赖"
cd ../modal-login
yarn add viem@2.25.0 @account-kit/react@latest next@latest
yarn install
cd ../rl-swarm

echo "🟢 启动脚本运行权限设置"
chmod +x run_rl_swarm.sh

echo "🚀 启动项目运行..."
./run_rl_swarm.sh

echo "✅ 全部完成！欢迎进入 Gensyn 的 RL Swarm 世界 🎉"
