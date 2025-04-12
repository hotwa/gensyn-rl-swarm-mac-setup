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
pip install protobuf==3.20.0 --no-cache-dir  # 使用符合 <5.28.0,>=3.12.2 的版本

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
pip install git+https://github.com/learning-at-home/hivemind.git@master --no-deps
pip install hivemind==1.1.5  # 使用稳定版本

# 修改run_rl_swarm.sh以添加内存限制（如果文件存在）
if [ ! -d "$HOME/rl-swarm" ]; then
  git clone https://github.com/zunxbt/rl-swarm.git ~/rl-swarm
fi

cd ~/rl-swarm

# 创建内存优化补丁
cat > ~/patches/memory_optimization.py << 'EOF'
#!/usr/bin/env python3
import os
import sys

def add_memory_optimization(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # 添加内存优化代码到python脚本开头
    memory_code = """
# 内存优化：强制垃圾回收
import gc
import torch
import os

# 启用主动垃圾回收
gc.enable()

# 降低批处理大小
os.environ['BATCH_SIZE'] = '4'  # 降低默认批次大小
os.environ['GRADIENT_ACCUMULATION_STEPS'] = '4'  # 使用梯度累积

# 限制PyTorch缓存
os.environ['PYTORCH_MPS_HIGH_WATERMARK_RATIO'] = '0.0'
os.environ['PYTORCH_MPS_ALLOCATOR_RESERVED_SIZE'] = '4096'
os.environ['PYTORCH_MPS_LOW_WATERMARK_RATIO'] = '0.5'
os.environ['PYTORCH_MPS_ALLOCATOR_FRAG_THRESHOLD'] = '0.5'

# 每轮强制清理内存
def clean_memory():
    gc.collect()
    torch.cuda.empty_cache() if torch.cuda.is_available() else None
    if hasattr(torch, 'mps') and torch.backends.mps.is_available():
        try:
            torch.mps.empty_cache()
        except:
            pass

# 定期调用clean_memory()
"""
    
    # 只有在没有这些代码的情况下才添加
    if "内存优化" not in content:
        modified = memory_code + content
        with open(file_path, 'w') as f:
            f.write(modified)
        print(f"已添加内存优化代码到: {file_path}")
    else:
        print(f"文件已包含内存优化代码: {file_path}")

def find_and_optimize_main_scripts(directory):
    main_scripts = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.py') and 'train' in file:
                main_scripts.append(os.path.join(root, file))
    
    for script in main_scripts:
        add_memory_optimization(script)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        find_and_optimize_main_scripts(sys.argv[1])
    else:
        print("请提供要优化的目录路径")
EOF

chmod +x ~/patches/memory_optimization.py

# 修复类型注解
python ~/patches/fix_type_annotations.py ~/rl-swarm

# 应用内存优化
python ~/patches/memory_optimization.py ~/rl-swarm

# 设置 MPS 内存优化参数（Mac 专用）
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
export PYTORCH_MPS_ALLOCATOR_RESERVED_SIZE=4096
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
export PYTORCH_MPS_ALLOCATOR_RESERVED_SIZE=4096
export PYTORCH_MPS_LOW_WATERMARK_RATIO=0.5
export PYTORCH_MPS_ALLOCATOR_FRAG_THRESHOLD=0.5

# 设置Python内存优化
export PYTHONMALLOC=malloc
export MALLOC_TRIM_THRESHOLD_=65536
export BATCH_SIZE=4
export GRADIENT_ACCUMULATION_STEPS=4

cd ~/rl-swarm

while [ $restart_count -lt $MAX_RESTARTS ]; do
    echo "启动RL-Swarm (运行次数: $((restart_count+1))/${MAX_RESTARTS})"
    echo "启动时间: $(date)"
    
    # 清理内存缓存（需要密码，可能跳过）
    # if command -v purge &> /dev/null; then
    #    echo "清理系统内存缓存..."
    #    sudo purge
    # fi
    
    # 运行脚本，并限制内存使用
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
        echo "重启前清理内存..."
        
        # 强制进行垃圾回收
        python -c "import gc; gc.collect()"
        
        echo "重启前休息60秒..."  # 增加等待时间
        sleep 60
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
