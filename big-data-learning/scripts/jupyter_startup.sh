#!/bin/bash
# Jupyter启动脚本 - 完整版本

echo "开始配置Jupyter和PySpark环境..."

# 注意：PySpark 需要手动安装以便学习过程可见
echo "跳过自动安装，等待手动安装 PySpark..."

# 配置PySpark环境变量
echo "配置PySpark环境变量..."
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH
export PYSPARK_PYTHON=/opt/conda/bin/python
export PYSPARK_DRIVER_PYTHON=/opt/conda/bin/python
export PYSPARK_DRIVER_PYTHON_OPTS="notebook"

# 创建工作目录
mkdir -p /home/jovyan/work/custom
mkdir -p /home/jovyan/work/examples

# 创建Spark连接测试脚本
echo "创建测试脚本..."
cat > /home/jovyan/work/test_spark_connection.py << 'EOL'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Spark连接测试脚本
用于验证Jupyter与Spark集群的连接
"""

from pyspark.sql import SparkSession
import sys

def test_spark_connection():
    """测试Spark连接"""
    try:
        # 创建SparkSession
        print("正在连接Spark集群...")
        spark = SparkSession.builder \
            .appName("SparkConnectionTest") \
            .master("spark://spark-master:7077") \
            .config("spark.sql.adaptive.enabled", "true") \
            .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
            .getOrCreate()

        # 测试连接
        print(f"✅ Spark版本: {spark.version}")
        print(f"✅ Spark应用ID: {spark.sparkContext.applicationId}")
        print(f"✅ Spark UI地址: {spark.sparkContext.uiWebUrl}")
        
        # 创建测试DataFrame
        print("\n创建测试DataFrame...")
        test_data = [("张三", 25, "北京"), ("李四", 30, "上海"), ("王五", 35, "广州")]
        columns = ["姓名", "年龄", "城市"]
        df = spark.createDataFrame(test_data, columns)
        
        print("测试DataFrame内容:")
        df.show()
        
        print(f"DataFrame行数: {df.count()}")
        print(f"DataFrame列数: {len(df.columns)}")
        
        # 简单的数据操作测试
        print("\n执行简单的数据操作...")
        avg_age = df.agg({"年龄": "avg"}).collect()[0][0]
        print(f"平均年龄: {avg_age:.1f}")
        
        # 停止SparkSession
        spark.stop()
        print("\n🎉 Spark连接测试成功！")
        return True
        
    except Exception as e:
        print(f"❌ Spark连接测试失败: {str(e)}")
        return False

if __name__ == "__main__":
    test_spark_connection()
EOL

# 创建欢迎笔记本
cat > /home/jovyan/work/00-welcome.ipynb << 'EOL'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 🎉 欢迎使用大数据学习平台！\n",
    "\n",
    "这是一个基于Docker的Apache Spark学习环境，包含：\n",
    "- Apache Spark 3.4 集群\n",
    "- Jupyter Notebook with PySpark\n",
    "- 丰富的学习材料和实践项目\n",
    "\n",
    "## 🚀 快速开始\n",
    "\n",
    "### 1. 测试Spark连接"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# 运行Spark连接测试\n",
    "exec(open('test_spark_connection.py').read())"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### 2. 简单的PySpark示例"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "from pyspark.sql import SparkSession\n",
    "\n",
    "# 创建SparkSession\n",
    "spark = SparkSession.builder \\\n",
    "    .appName(\"Welcome\") \\\n",
    "    .master(\"spark://spark-master:7077\") \\\n",
    "    .getOrCreate()\n",
    "\n",
    "# 创建简单的DataFrame\n",
    "data = [(\"Alice\", 25), (\"Bob\", 30), (\"Charlie\", 35)]\n",
    "df = spark.createDataFrame(data, [\"name\", \"age\"])\n",
    "\n",
    "print(\"DataFrame内容:\")\n",
    "df.show()\n",
    "\n",
    "print(f\"总行数: {df.count()}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### 3. 学习路径\n",
    "\n",
    "建议按以下顺序学习：\n",
    "\n",
    "1. **Spark基础** (`01-spark-basics/`)\n",
    "   - RDD基础操作\n",
    "   - DataFrame API\n",
    "   - Dataset API\n",
    "\n",
    "2. **Spark SQL** (`02-spark-sql/`)\n",
    "   - SQL基础查询\n",
    "   - 高级查询技巧\n",
    "   - 性能调优\n",
    "\n",
    "3. **Spark Streaming** (`03-spark-streaming/`)\n",
    "   - 流处理基础\n",
    "   - 结构化流\n",
    "   - Kafka集成\n",
    "\n",
    "4. **实践项目** (`04-projects/`)\n",
    "   - 日志分析\n",
    "   - 推荐系统\n",
    "   - 实时仪表盘\n",
    "\n",
    "### 4. 有用的链接\n",
    "\n",
    "- **Spark Master UI**: http://localhost:8080\n",
    "- **Spark应用UI**: http://localhost:4040 (运行作业时)\n",
    "- **学习路径**: [learning_path.md](learning_path.md)\n",
    "\n",
    "祝学习愉快！🎓"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.11.6"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOL

echo "✅ Jupyter环境配置完成！"
echo "📚 已创建欢迎笔记本和测试脚本"
echo "🚀 正在启动Jupyter Lab..."

# 启动Jupyter Lab
# 确保环境变量在 Jupyter 进程中可用
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH

exec /opt/conda/bin/jupyter lab \
    --NotebookApp.token='' \
    --NotebookApp.password='' \
    --NotebookApp.allow_root=True \
    --ip='0.0.0.0' \
    --port=8888 \
    --no-browser