#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复Jupyter Notebook中的Python环境问题
"""

import os
import sys

def fix_python_environment():
    """
    修复Python环境问题
    """
    # 确保/opt/conda/bin在PATH中
    conda_bin_path = "/opt/conda/bin"
    current_path = os.environ.get("PATH", "")
    
    if conda_bin_path not in current_path:
        os.environ["PATH"] = f"{conda_bin_path}:{current_path}"
        print(f"✅ 已将 {conda_bin_path} 添加到 PATH")
    else:
        print(f"✅ {conda_bin_path} 已在 PATH 中")
    
    # 验证python命令是否可用
    import subprocess
    try:
        result = subprocess.run(["python", "--version"], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print(f"✅ Python命令可用: {result.stdout.strip()}")
        else:
            print("❌ Python命令不可用")
            print(f"错误信息: {result.stderr}")
    except Exception as e:
        print(f"❌ 执行python命令时出错: {e}")

if __name__ == "__main__":
    fix_python_environment()