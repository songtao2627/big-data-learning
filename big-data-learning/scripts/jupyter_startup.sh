#!/bin/bash
# Jupyter启动脚本 - 安装额外的Python库和配置

# 安装额外的Python库
pip install --no-cache-dir \
    pyspark==3.4.0 \
    findspark \
    pyarrow \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    plotly \
    bokeh \
    scikit-learn \
    jupyterlab-git \
    jupyterlab-drawio \
    sparkmonitor

# 配置PySpark
echo "配置PySpark环境..."
export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9-src.zip:$PYTHONPATH
export PYSPARK_PYTHON=/opt/conda/bin/python
export PYSPARK_DRIVER_PYTHON=/opt/conda/bin/python

# 创建自定义目录
mkdir -p /home/jovyan/work/custom

# 创建自定义CSS
cat > /home/jovyan/work/custom/custom.css << EOL
/* 自定义Jupyter样式 */
.jp-Notebook {
    font-family: 'Source Han Sans CN', sans-serif;
}

.jp-MarkdownCell {
    font-size: 16px;
}

.jp-CodeCell {
    font-size: 14px;
}

/* 代码单元格样式 */
.jp-CodeMirrorEditor {
    border-left: 3px solid #2196F3;
    padding-left: 5px;
}

/* 输出单元格样式 */
.jp-OutputArea-output {
    border-left: 3px solid #4CAF50;
    padding-left: 5px;
}

/* 错误输出样式 */
.jp-OutputArea-output.jp-OutputArea-executeResult.jp-RenderedText[data-mime-type="application/vnd.jupyter.stderr"] {
    border-left: 3px solid #F44336;
}
EOL

# 创建自定义JS
cat > /home/jovyan/work/custom/custom.js << EOL
// 自定义Jupyter JavaScript
require(['base/js/namespace'], function(Jupyter) {
    // 自动显示所有变量
    Jupyter.notebook.events.on('kernel_ready.Kernel', function() {
        console.log('Kernel ready, auto-displaying variables');
        Jupyter.notebook.kernel.execute('%config IPCompleter.greedy=True');
    });
});
EOL

# 创建Spark连接测试脚本
cat > /home/jovyan/work/test_spark_connection.py << EOL
from pyspark.sql import SparkSession

# 创建SparkSession
spark = SparkSession.builder \\
    .appName("SparkConnectionTest") \\
    .master("spark://spark-master:7077") \\
    .getOrCreate()

# 测试连接
print("Spark版本:", spark.version)
print("Spark应用ID:", spark.sparkContext.applicationId)
print("Spark UI地址:", spark.sparkContext.uiWebUrl)

# 创建测试DataFrame
test_data = [("张三", 25), ("李四", 30), ("王五", 35)]
df = spark.createDataFrame(test_data, ["name", "age"])
print("测试DataFrame:")
df.show()

# 停止SparkSession
spark.stop()
EOL

echo "Jupyter环境配置完成！"