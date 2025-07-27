#!/usr/bin/env python3
"""
容器开发环境快速测试脚本
"""

import sys
import os
from datetime import datetime

def print_section(title):
    print(f"\n🧪 {title}")
    print('-' * 40)

def test_spark_connection():
    """测试 Spark 集群连接"""
    print_section("Spark 集群连接测试")
    
    try:
        from pyspark.sql import SparkSession
        
        spark = SparkSession.builder \
            .appName("ContainerTest") \
            .master("spark://spark-master:7077") \
            .getOrCreate()
        
        spark.sparkContext.setLogLevel("WARN")
        
        print(f"✅ Spark 版本: {spark.version}")
        print(f"✅ 集群连接成功")
        
        # 简单测试
        data = [(1, "测试"), (2, "数据")]
        df = spark.createDataFrame(data, ["id", "name"])
        count = df.count()
        print(f"✅ 数据处理测试通过 (记录数: {count})")
        
        spark.stop()
        return True
        
    except Exception as e:
        print(f"❌ Spark 连接失败: {str(e)}")
        return False

def test_spark_connection():
    """测试 Spark 集群连接"""
    print_section("Spark 集群连接测试")
    
    try:
        from pyspark.sql import SparkSession
        
        # 创建 Spark 会话
        print("🔗 连接到 Spark 集群...")
        spark = SparkSession.builder \
            .appName("ContainerEnvironmentTest") \
            .master("spark://spark-master:7077") \
            .config("spark.executor.memory", "1g") \
            .config("spark.driver.memory", "512m") \
            .getOrCreate()
        
        # 设置日志级别
        spark.sparkContext.setLogLevel("WARN")
        
        print(f"✅ Spark 版本: {spark.version}")
        print(f"✅ Master URL: {spark.sparkContext.master}")
        print(f"✅ 应用名称: {spark.sparkContext.appName}")
        print(f"✅ 应用 ID: {spark.sparkContext.applicationId}")
        
        # 测试基本操作
        print("\n🧮 测试基本 Spark 操作...")
        
        # 创建测试数据
        data = [(1, "Alice", 25), (2, "Bob", 30), (3, "Charlie", 35)]
        columns = ["id", "name", "age"]
        df = spark.createDataFrame(data, columns)
        
        print("📊 创建测试 DataFrame:")
        df.show()
        
        # 测试 SQL 查询
        df.createOrReplaceTempView("people")
        result = spark.sql("SELECT name, age FROM people WHERE age > 25")
        print("🔍 SQL 查询结果 (age > 25):")
        result.show()
        
        # 测试聚合操作
        avg_age = df.agg({"age": "avg"}).collect()[0][0]
        print(f"📈 平均年龄: {avg_age:.1f}")
        
        # 获取集群信息
        print("\n🖥️  集群信息:")
        print(f"  默认并行度: {spark.sparkContext.defaultParallelism}")
        print(f"  Executor 数量: {len(spark.sparkContext.statusTracker().getExecutorInfos()) - 1}")
        
        spark.stop()
        print("\n✅ Spark 集群测试通过")
        return True
        
    except Exception as e:
        print(f"❌ Spark 连接失败: {str(e)}")
        print("\n🔧 故障排除建议:")
        print("1. 检查 Spark 集群是否启动: docker-compose ps")
        print("2. 检查网络连接: docker exec -it spark-dev ping spark-master")
        print("3. 查看 Master 日志: docker-compose logs spark-master")
        return False

def test_data_access():
    """测试数据目录访问"""
    print_section("数据目录访问测试")
    
    data_dir = "/opt/bitnami/spark/data"
    notebooks_dir = "/opt/bitnami/spark/notebooks"
    
    # 检查目录是否存在
    directories = [
        (data_dir, "数据目录"),
        (notebooks_dir, "Notebooks 目录"),
        ("/opt/bitnami/spark/scripts", "脚本目录")
    ]
    
    for dir_path, dir_name in directories:
        if os.path.exists(dir_path):
            files = os.listdir(dir_path)
            print(f"✅ {dir_name}: {dir_path} ({len(files)} 个文件/目录)")
            if files:
                print(f"   内容示例: {', '.join(files[:5])}")
        else:
            print(f"❌ {dir_name}: {dir_path} 不存在")
    
    # 测试文件读写
    test_file = os.path.join(data_dir, "test_write.txt")
    try:
        with open(test_file, 'w') as f:
            f.write(f"测试时间: {datetime.now()}")
        
        with open(test_file, 'r') as f:
            content = f.read()
        
        os.remove(test_file)
        print("✅ 文件读写测试通过")
        return True
        
    except Exception as e:
        print(f"❌ 文件读写测试失败: {str(e)}")
        return False

def test_jupyter_config():
    """测试 Jupyter 配置"""
    print_section("Jupyter 配置测试")
    
    try:
        import jupyter_core
        import jupyterlab
        
        print(f"✅ Jupyter Core 版本: {jupyter_core.__version__}")
        print(f"✅ JupyterLab 版本: {jupyterlab.__version__}")
        
        # 检查配置文件
        config_file = os.path.expanduser("~/.jupyter/jupyter_lab_config.py")
        if os.path.exists(config_file):
            print(f"✅ 配置文件存在: {config_file}")
        else:
            print(f"⚠️  配置文件不存在: {config_file}")
        
        # 检查 PySpark 初始化文件
        pyspark_init = "/opt/bitnami/spark/notebooks/pyspark_init.py"
        if os.path.exists(pyspark_init):
            print(f"✅ PySpark 初始化文件存在: {pyspark_init}")
        else:
            print(f"⚠️  PySpark 初始化文件不存在: {pyspark_init}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Jupyter 导入失败: {str(e)}")
        return False

def test_network_connectivity():
    """测试网络连通性"""
    print_section("网络连通性测试")
    
    import socket
    
    # 测试服务连接
    services = [
        ("spark-master", 7077, "Spark Master"),
        ("spark-master", 8080, "Spark Master UI"),
        ("spark-worker-1", 8881, "Spark Worker 1"),
        ("spark-worker-2", 8882, "Spark Worker 2")
    ]
    
    for host, port, service in services:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((host, port))
            sock.close()
            
            if result == 0:
                print(f"✅ {service}: {host}:{port} - 连接成功")
            else:
                print(f"❌ {service}: {host}:{port} - 连接失败")
                
        except Exception as e:
            print(f"❌ {service}: {host}:{port} - 测试失败: {str(e)}")

def test_basic_network():
    """测试基本网络连通性"""
    print_section("网络连通性测试")
    
    import socket
    
    # 测试关键服务连接
    services = [
        ("spark-master", 7077, "Spark Master"),
        ("spark-master", 8080, "Spark Master UI"),
        ("spark-worker-1", 8881, "Spark Worker 1"),
        ("spark-worker-2", 8882, "Spark Worker 2")
    ]
    
    network_ok = True
    for host, port, service in services:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(3)
            result = sock.connect_ex((host, port))
            sock.close()
            
            if result == 0:
                print(f"✅ {service}: {host}:{port}")
            else:
                print(f"❌ {service}: {host}:{port} - 连接失败")
                network_ok = False
                
        except Exception as e:
            print(f"❌ {service}: {host}:{port} - 异常: {str(e)}")
            network_ok = False
    
    return network_ok

def main():
    """主测试函数"""
    print("🚀 容器开发环境快速测试")
    print(f"⏰ 时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 检查基本环境
    print(f"\n📋 环境信息:")
    print(f"  Python: {sys.version.split()[0]}")
    print(f"  工作目录: {os.getcwd()}")
    
    # 测试网络连通性
    network_ok = test_basic_network()
    
    # 测试 Spark 连接
    spark_ok = test_spark_connection()
    
    if network_ok and spark_ok:
        print("\n🎉 环境测试通过！")
        print("\n💡 快速开始:")
        print("  • Jupyter Lab: http://localhost:8888 (token: spark-learning)")
        print("  • 示例 Notebook: container-spark-demo.ipynb")
        print("  • Spark UI: http://localhost:8080")
        print("\n🔍 详细网络测试:")
        print("  • 运行: python3 test_network_connectivity.py")
    else:
        print("\n❌ 环境测试失败")
        if not network_ok:
            print("  ⚠️  网络连通性问题")
        if not spark_ok:
            print("  ⚠️  Spark 连接问题")
        print("\n🔧 故障排除:")
        print("  • 检查容器状态: docker-compose ps")
        print("  • 网络诊断: python3 test_network_connectivity.py")
        print("  • 重启环境: docker-compose restart spark-dev")
        print("  • 查看日志: docker-compose logs spark-dev")

if __name__ == "__main__":
    main()