# 安装Homebrew（如果还没安装的话）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装指定版本的Python 3.10
brew install python@3.10

# 创建新的虚拟环境
python3.10 -m venv rl_env310

# 激活虚拟环境
source rl_env310/bin/activate

# 验证Python是否安装成功
python3 --version
# 输出版本号，说明安装成功

# 安装cloudflared
brew install cloudflared

# 将homebrew加入到变量环境
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc

# 立即生效
source ~/.zshrc

# 创建python软链接到python3
sudo ln -s /usr/local/bin/python3 /usr/local/bin/python

# 克隆仓库
git clone https://github.com/zunxbt/rl-swarm.git && cd rl-swarm

# 安装Node.js和Yarn
brew install node
npm install -g yarn

# 安装hivemind
pip install hivemind

sudo chown -R 501:20 "/Users/macmini/.npm"

# 设置内存优化
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# 赋予权限并运行
chmod +x run_rl_swarm.sh
./run_rl_swarm.sh
