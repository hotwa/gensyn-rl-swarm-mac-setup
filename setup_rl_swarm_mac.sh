#!/bin/bash

# 安装 Homebrew（如果尚未安装）
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # 添加Homebrew到PATH（适用于当前会话）
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 安装 Python 3.10
brew install python@3.10

# 创建虚拟环境
/opt/homebrew/bin/python3.10 -m venv ~/rl_env310
source ~/rl_env310/bin/activate

# 验证 Python 安装成功
python --version

# 安装 cloudflared
brew install cloudflared

# 安装 Node.js 和 Yarn
brew install node
npm install -g yarn

# 修复 npm 权限
sudo chown -R $(id -u):$(id -g) ~/.npm

# 安装主要依赖（先安装基础包）
pip install torch torchvision torchaudio
pip install pydantic>=2.0

# 卸载所有 protobuf 版本，避免版本冲突
pip uninstall -y protobuf

# 安装 protobuf 5.27.5（必须与 hivemind 兼容）
pip install protobuf==5.27.5 --no-cache-dir

# 安装 hivemind 主分支
pip install git+https://github.com/learning-at-home/hivemind.git@main

# 克隆项目仓库（如果不存在）
if [ ! -d "$HOME/rl-swarm" ]; then
  git clone https://github.com/zunxbt/rl-swarm.git ~/rl-swarm
fi
cd ~/rl-swarm

# 设置 MPS 内存优化参数（Mac 专用）
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
# 添加内存限制参数
export PYTORCH_MPS_ALLOCATOR_RESERVED_SIZE=4096  # 限制4GB内存使用

# 添加可执行权限并运行脚本，限制内存使用
chmod +x run_rl_swarm.sh
# 使用ulimit限制内存使用
ulimit -v 12000000  # 限制虚拟内存使用约12GB
./run_rl_swarm.sh
