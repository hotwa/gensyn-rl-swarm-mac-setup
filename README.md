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

ss 命令报错解决

```shell
sudo tee /usr/local/bin/ss > /dev/null << 'EOF'
#!/bin/bash
# 简单模拟 Linux ss，参数原样转给 netstat -an
netstat -an "$@"
EOF
sudo chmod +x /usr/local/bin/ss
```

## NAT4 fix

```shell
hivemind.p2p.p2p_daemon_bindings.utils.P2PDaemonError: Daemon failed to start: 2025/05/07 09:54:31 failed to connect to bootstrap peers
```

vim ~/rl-swarm/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

```shell
def setup_dht(self, grpo_args):
        # dht = super().setup_dht(grpo_args)
        peer_id = str(dht.peer_id)
        self.register_peer(peer_id)
        return dht
```

```shell
-        dht = hivemind.DHT(
-            start=True,
-            startup_timeout=30,
-            **self._dht_kwargs(grpo_args)
-        )
+        dht = hivemind.DHT(
+            start=True,
+            client_mode=True,
             use_ipfs=True, # 走中继模式
+            ensure_bootstrap_success=False,
+            startup_timeout=30,
+            **self._dht_kwargs(grpo_args)
+        )

```

## AttributeError: 'TestnetGRPORunner' object has no attribute 'name'

edit ~/rl-swarm/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

```shell
--- a/hivemind_exp/runner/gensyn/testnet_grpo_runner.py
+++ b/hivemind_exp/runner/gensyn/testnet_grpo_runner.py
@@ class TestnetGRPORunner(GRPORunner):
     def __init__(self, coordinator: SwarmCoordinator) -> None:
-        self.coordinator = coordinator
+        super().__init__()             # 如果父类需要初始化，也一并调用
+        self.coordinator = coordinator
+        self.name = "TestnetGRPO"      # ← 定义一个名称，用于日志 log_tag

```

## auto restart 

```shell
~/rl-swarm/auto_restart.sh
```

## NameError: name 'hivemind' is not defined

vim ~/rl-swarm/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

add in top line

```shell
import hivemind
```

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



