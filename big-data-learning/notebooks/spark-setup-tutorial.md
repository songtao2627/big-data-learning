# 🔧 Spark 环境手动配置和调试教程

## 学习目标
通过手动配置 PySpark 环境，深入理解：
- 版本兼容性问题
- 环境变量配置
- 依赖管理
- 分布式系统调试方法

## 前置知识回顾

### 我们发现的问题
1. **表面现象**：`df.show()` 卡住
2. **根本原因**：Jupyter 容器中的 Spark 版本（3.5.0）与集群版本（3.4.x）不匹配
3. **解决方案**：安装匹配的 PySpark 版本

## 🚀 手动配置步骤

### 步骤1：进入 Jupyter 容器

首先启动 Jupyter 容器（不带自动安装）：

```bash
# 在宿主机执行
docker-compose up -d jupyter
```

等待容器启动后，进入容器：

```bash
# 进入容器的 bash 环境
docker-compose exec jupyter bash
```

### 步骤2：检查当前环境

在容器内执行以下命令，了解当前状态：

```bash
# 检查 Python 版本
python --version

# 检查当前安装的包
pip list | grep -i spark

# 检查环境变量
echo "SPARK_HOME: $SPARK_HOME"
echo "PYTHONPATH: $PYTHONPATH"

# 检查 Spark 安装位置
find /usr/local -name "spark*" -type d 2>/dev/null
```

### 步骤3：卸载现有的 PySpark（如果存在）

```bash
# 卸载可能存在的 PySpark
pip uninstall pyspark -y

# 验证卸载
python -c "import pyspark" 2>&1 || echo "PySpark 已成功卸载"
```

### 步骤4：安装匹配版本的 PySpark

```bash
# 安装与集群匹配的 PySpark 版本
pip install pyspark==3.4.3

# 验证安装
python -c "import pyspark; print('PySpark version:', pyspark.__version__)"
```

### 步骤5：安装辅助工具

```bash
# 安装有用的辅助库
pip install findspark pyarrow

# findspark 可以帮助自动找到 Spark 安装位置
```

### 步骤6：配置环境变量

```bash
# 设置环境变量（临时）
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH

# 验证配置
echo "SPARK_HOME: $SPARK_HOME"
echo "PYTHONPATH: $PYTHONPATH"
```

### 步骤7：测试本地模式

创建一个测试脚本：

```bash
# 创建测试文件
cat > test_local_spark.py << 'EOF'
import sys
print("Python path:", sys.path)

try:
    from pyspark.sql import SparkSession
    print("✅ PySpark 导入成功")
    
    # 测试本地模式
    spark = SparkSession.builder \
        .appName("LocalTest") \
        .master("local[2]") \
        .getOrCreate()
    
    print(f"✅ Spark 版本: {spark.version}")
    
    # 简单测试
    df = spark.createDataFrame([(1, "test")], ["id", "name"])
    df.show()
    
    spark.stop()
    print("✅ 本地模式测试成功")
    
except Exception as e:
    print(f"❌ 错误: {e}")
EOF

# 运行测试
python test_local_spark.py
```

### 步骤8：测试集群连接

```bash
# 创建集群连接测试
cat > test_cluster_spark.py << 'EOF'
from pyspark.sql import SparkSession
import time

try:
    print("连接到 Spark 集群...")
    spark = SparkSession.builder \
        .appName("ClusterTest") \
        .master("spark://spark-master:7077") \
        .config("spark.driver.memory", "512m") \
        .config("spark.executor.memory", "1g") \
        .config("spark.executor.cores", "1") \
        .getOrCreate()
    
    print(f"✅ 集群连接成功，Spark 版本: {spark.version}")
    print(f"✅ 应用 ID: {spark.sparkContext.applicationId}")
    
    # 测试简单操作
    rdd = spark.sparkContext.parallelize([1, 2, 3, 4, 5])
    result = rdd.sum()
    print(f"✅ RDD 测试成功，求和结果: {result}")
    
    # 测试 DataFrame
    df = spark.createDataFrame([(1, "张三"), (2, "李四")], ["id", "name"])
    print("✅ DataFrame 创建成功")
    
    # 这里是之前卡住的地方
    print("执行 df.show()...")
    df.show()
    print("✅ df.show() 执行成功！")
    
    spark.stop()
    print("🎉 集群测试完全成功！")
    
except Exception as e:
    print(f"❌ 集群测试失败: {e}")
    import traceback
    traceback.print_exc()
EOF

# 运行集群测试
python test_cluster_spark.py
```

## 🔍 调试技巧

### 如果遇到问题，按以下顺序检查：

#### 1. 版本检查
```bash
# 检查 PySpark 版本
python -c "import pyspark; print(pyspark.__version__)"

# 检查集群版本（在宿主机执行）
docker-compose logs spark-master | grep -i version
```

#### 2. 网络连接检查
```bash
# 在容器内测试网络连接
ping spark-master
telnet spark-master 7077
```

#### 3. 资源检查
```bash
# 检查容器资源
docker stats --no-stream
```

#### 4. 日志检查
```bash
# 查看 Spark Master 日志
docker-compose logs spark-master --tail=20

# 查看 Worker 日志
docker-compose logs spark-worker-1 --tail=20
```

## 🎓 学习要点总结

### 版本兼容性
- **客户端版本** = **服务端版本** 是分布式系统的基本要求
- 版本不匹配会在序列化/反序列化时暴露问题
- 使用 `pip install pyspark==具体版本` 确保版本一致

### 环境变量重要性
- `SPARK_HOME`: Spark 安装目录
- `PYTHONPATH`: Python 模块搜索路径
- 环境变量必须在 Python 进程启动前设置

### 调试方法论
1. **分层调试**: 从简单到复杂（本地模式 → 集群模式）
2. **逐步验证**: 导入 → 连接 → 简单操作 → 复杂操作
3. **日志分析**: 查看各组件日志找到根本原因

### Spark 执行模型
- **Transformation**: 懒执行，不会立即暴露问题
- **Action**: 触发实际计算，问题在这里暴露
- 理解这个区别有助于定位问题

## 🚀 下一步

完成手动配置后，你可以：
1. 在 Jupyter Notebook 中创建新的 notebook
2. 使用配置好的环境学习 Spark 基础概念
3. 逐步学习更复杂的 Spark 功能

## 💡 专业提示

- 每次重启容器后需要重新设置环境变量
- 可以将环境变量设置写入 `~/.bashrc` 使其持久化
- 使用 `findspark.init()` 可以自动配置 PySpark 路径
- 在生产环境中，版本管理更加重要