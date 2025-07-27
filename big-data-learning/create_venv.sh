# 创建虚拟环境
python -m venv .venv

# 激活虚拟环境（示例为 Unix/Linux/MacOS）
source .venv/bin/activate

# 激活虚拟环境（示例为 Windows）
# .venv\Scripts\activate
# 安装 IPython 和 ipykernel
pip install ipython
pip install ipykernel

# 安装内核
python -m ipykernel install --user --name=.venv --display-name "Python (.venv)"

# 安装 pyspark
pip install pyspark
