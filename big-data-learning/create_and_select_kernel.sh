# 激活虚拟环境（示例为 Unix/Linux/MacOS）
source .venv/bin/activate

# 安装 IPython 和 ipykernel
pip install ipython
pip install ipykernel

# 安装内核
python -m ipykernel install --user --name=.venv --display-name "Python (.venv)"

# 启动 Jupyter Notebook
jupyter notebook