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

# 安装正确版本的依赖
pip install idna>=3.10
pip install protobuf==5.28.1 --no-cache-dir  # 使用稳定版本

# 安装其他依赖
pip install grpcio pybind11 pkgconfig typing_extensions

# 创建补丁文件解决类型注解问题
mkdir -p ~/patches
cat > ~/patches/fix_type_annotations.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import re

def fix_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # 替换 float | int 为 Union[float, int]
    modified = re.sub(r'(\w+)\s*\|\s*(\w+)', r'Union[\1, \2]', content)
    
    # 如果文件被修改，添加Union导入
    if modified != content and 'from typing import Union' not in modified:
        if 'from typing import ' in modified:
            modified = re.sub(r'from typing import (.*)', r'from typing import \1, Union', modified)
        else:
            modified = 'from typing import Union\n' + modified
    
    # 只有在文件被修改的情况下才写入
    if modified != content:
        print(f"修复类型注解: {file_path}")
        with open(file_path, 'w') as f:
            f.write(modified)

def fix_directory(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.py'):
                fix_file(os.path.join(root, file))

if __name__ == "__main__":
    if len(sys.argv) > 1:
        fix_directory(sys.argv[1])
    else:
        print("请提供要修复的目录路径")
EOF

chmod +x ~/patches/fix_type_annotations.py

# 安装hivemind
pip install git+https://github.com/learning-at-home/hivemind.git@master

# 克隆项目仓库（如果不存在）
if [ ! -d "$HOME/rl-swarm" ]; then
  git clone https://github.com/zunxbt/rl-swarm.git ~/rl-swarm
fi
cd ~/rl-swarm

# 修复类型注解
python ~/patches/fix_type_annotations.py ~/rl-swarm

# 设置 MPS 内存优化参数（Mac 专用）
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
# 添加内存限制参数
export PYTORCH_MPS_ALLOCATOR_RESERVED_SIZE=6144  # 增加内存限制到6GB

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
source ~/rl_env310/bin/activate

# 设置内存优化参数
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
export PYTORCH_MPS_ALLOCATOR_RESERVED_SIZE=6144
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
        echo "重启前休息30秒..."  # 增加等待时间
        sleep 30
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
