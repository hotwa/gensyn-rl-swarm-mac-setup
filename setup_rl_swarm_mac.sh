# 安装 Homebrew（如果还没安装的话）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 pyenv 和 pyenv-virtualenv（用于安装并管理 Python 3.10）
brew install pyenv pyenv-virtualenv

# 设置 pyenv 环境变量
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc
source ~/.zshrc

# 安装指定版本的 Python 3.10（如果还没有）
pyenv install 3.10.13

# 创建新的虚拟环境
pyenv virtualenv 3.10.13 rl_env

# 激活虚拟环境
pyenv activate rl_env

# 验证 Python 是否安装成功
python --version
# 输出 3.10.x 版本号，说明安装成功

# 安装 cloudflared
brew install cloudflared

# 将 homebrew 加入到变量环境
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc

# 立即生效
source ~/.zshrc

# 创建 python 软链接到 python3（可选，因为 pyenv 已管理）
# sudo ln -s /usr/local/bin/python3 /usr/local/bin/python

# 克隆仓库
git clone https://github.com/zunxbt/rl-swarm.git && cd rl-swarm

# 安装 Node.js 和 Yarn
brew install node
npm install -g yarn

# 安装 hivemind
pip install hivemind

# 修复 npm 权限问题
sudo chown -R 501:20 "/Users/macmini/.npm"

# 设置内存优化（适用于 Apple Silicon）
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# 赋予权限并运行
chmod +x run_rl_swarm.sh
./run_rl_swarm.sh
