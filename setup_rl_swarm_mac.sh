#!/bin/bash

# 安装 Homebrew（如果尚未安装）
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 添加 Homebrew 路径到环境变量
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 安装 Python 3.10
brew install python@3.10

# 创建虚拟环境
/opt/homebrew/bin/python3.10 -m venv ~/rl_env310
source ~/rl_env310/bin/activate

# 验证 Python 安装成功
python3 --version

# 安装 cloudflared
brew install cloudflared

# 安装 Node.js 和 Yarn
brew install node
npm install -g yarn

# 修复 npm 权限（根据你的用户名可改）
sudo chown -R $(id -u):$(id -g) ~/.npm

# 安装兼容 pydantic>=2.0 的 hivemind 最新主分支
pip install git+https://github.com/learning-at-home/hivemind.git@main

# 安装其他依赖包
pip install torch torchvision torchaudio

# 安装 protobuf 5.27.5，确保与 hivemind 兼容
pip install protobuf==5.27.5

# 安装 pydantic 兼容版本
pip install pydantic>=2.0

# 克隆项目仓库（如果不存在）
if [ ! -d "$HOME/rl-swarm" ]; then
  git clone https://github.com/zunxbt/rl-swarm.git ~/rl-swarm
fi
cd ~/rl-swarm

# 设置 MPS 内存优化参数（Mac 专用）
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# 添加可执行权限并运行脚本
chmod +x run_rl_swarm.sh
./run_rl_swarm.sh
