#!/bin/bash

# 安装 Homebrew（如果尚未安装）
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # 添加Homebrew到PATH（适用于当前会话）
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 安装 Python 3.9
brew install python@3.9

# 创建虚拟环境
/opt/homebrew/bin/python3.9 -m venv ~/rl_env39
source ~/rl_env39/bin/activate

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

# 安装与hivemind兼容的protobuf版本（5.27.0而不是5.27.5）
pip install protobuf==5.27.0 --no-cache-dir

# 安装其他依赖（这些可能是hivemind需要的）
pip install grpcio pybind11 pkgconfig

# 使用--no-deps安装hivemind，以避免它覆盖我们手动安装的protobuf
pip install git+https://github.com/learning-at-home/hivemind.git@master --no-deps

# 再次检查安装的protobuf版本并输出，确保仍然是兼容的版本
echo "当前安装的protobuf版本:"
pip list | grep protobuf

# 克隆项目仓库（如果不存在）
if [ ! -d "$HOME/rl-swarm" ]; then
  git clone https://github.com/zunxbt/rl-swarm.git ~/rl-swarm
fi
cd ~/rl-swarm

# 设置 MPS 内存优化参数（Mac 专用）
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
# 添加内存限制参数
export PYTORCH_MPS_ALLOCATOR_RESERVED_SIZE=4096  # 限制4GB内存使用

# 添加更多内存优化设置
export PYTORCH_MPS_LOW_WATERMARK_RATIO=0.5
export PYTORCH_MPS_ALLOCATOR_FRAG_THRESHOLD=0.5

# 添加可执行权限
chmod +x run_rl_swarm.sh

# 创建自动重启监控脚本
cat > auto_restart.sh << 'EOF'
#!/bin/bash

# 设置最大重启次数
MAX_RESTARTS=100
restart_count=0

# 激活虚拟环境
source ~/rl_env39/bin/activate

# 设置内存优化参数
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
export PYTORCH_MPS_ALLOCATOR_RESERVED_SIZE=4096
export PYTORCH_MPS_LOW_WATERMARK_RATIO=0.5
export PYTORCH_MPS_ALLOCATOR_FRAG_THRESHOLD=0.5

cd ~/rl-swarm

while [ $restart_count -lt $MAX_RESTARTS ]; do
    echo "启动RL-Swarm (运行次数: $((restart_count+1))/${MAX_RESTARTS})"
    echo "启动时间: $(date)"
    
    # 运行脚本
    ./run_rl_swarm.sh
    
    # 获取退出状态
    exit_status=$?
    
    # 检查是否是正常退出(0)或SIGINT(130)
    if [ $exit_status -eq 0 ]; then
        echo "脚本正常结束，停止自动重启"
        break
    elif [ $exit_status -eq 130 ]; then
        echo "检测到手动中断(Ctrl+C)，停止自动重启"
        break
    else
        restart_count=$((restart_count+1))
        echo "脚本异常退出(状态码: $exit_status)，准备重启..."
        echo "重启前休息10秒..."
        sleep 10
    fi
done

if [ $restart_count -ge $MAX_RESTARTS ]; then
    echo "已达到最大重启次数(${MAX_RESTARTS})，停止自动重启"
fi
EOF

# 给自动重启脚本添加执行权限
chmod +x auto_restart.sh

# 运行自动重启脚本
echo "启动带自动重启功能的RL-Swarm"
./auto_restart.sh
