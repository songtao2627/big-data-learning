#!/bin/bash
# 容器内镜像源配置脚本

echo "🔧 配置国内镜像源..."

# 1. 配置 pip 镜像源
echo "📦 配置 pip 镜像源..."
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
retries = 5

[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

# 2. 配置 apt 镜像源 (Ubuntu/Debian)
if [ -f /etc/apt/sources.list ]; then
    echo "🐧 配置 apt 镜像源..."
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    
    # 替换为清华大学镜像源
    sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
    
    # 更新包列表
    apt-get update
fi

# 3. 配置 conda 镜像源 (如果存在)
if command -v conda &> /dev/null; then
    echo "🐍 配置 conda 镜像源..."
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
    conda config --set show_channel_urls yes
fi

# 4. 测试 pip 安装速度
echo "🧪 测试 pip 安装速度..."
time pip install --no-cache-dir requests

echo "✅ 镜像源配置完成！"

# 显示配置信息
echo ""
echo "📋 当前配置："
echo "  pip 配置文件: ~/.pip/pip.conf"
if [ -f /etc/apt/sources.list.bak ]; then
    echo "  apt 源备份: /etc/apt/sources.list.bak"
fi

echo ""
echo "💡 使用方法："
echo "  pip install package-name  # 自动使用国内镜像源"
echo "  apt-get install package   # 使用国内 apt 源"