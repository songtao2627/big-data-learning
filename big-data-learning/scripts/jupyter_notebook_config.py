# Jupyter Notebook配置文件

# 基本配置
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '/home/jovyan/work'
c.NotebookApp.allow_root = True

# 安全配置
c.NotebookApp.token = ''  # 在生产环境中应设置强密码
c.NotebookApp.password = ''  # 在生产环境中应设置密码哈希

# 界面配置
c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}
c.NotebookApp.enable_mathjax = True

# 自动保存配置
c.ContentsManager.allow_hidden = True
c.FileContentsManager.auto_save_interval = 120  # 自动保存间隔（秒）

# 执行配置
c.InteractiveShellApp.extensions = [
    'sparkmonitor.kernelextension'
]

# 显示配置
c.NotebookApp.tornado_settings = {
    'headers': {
        'Content-Security-Policy': "frame-ancestors 'self' *"
    }
}

# PySpark配置
spark_opts = [
    "--master=spark://spark-master:7077",
    "--executor-memory=512m",
    "--driver-memory=512m",
    "--executor-cores=1",
    "--packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0",
    "--conf spark.ui.port=4040",
    "--conf spark.sql.execution.arrow.pyspark.enabled=true"
]

c.ServerApp.jpserver_extensions = {
    'sparkmonitor.serverextension': True
}

# 自定义CSS和JS
c.NotebookApp.extra_static_paths = ['/home/jovyan/work/custom']

# 自动导入的库
c.InteractiveShellApp.exec_lines = [
    'import numpy as np',
    'import pandas as pd',
    'import matplotlib.pyplot as plt',
    'plt.style.use("ggplot")',
    'plt.rcParams["figure.figsize"] = (12, 8)',
    '%matplotlib inline'
]

# 设置默认编辑器主题
c.LabApp.theme = 'JupyterLab Dark'