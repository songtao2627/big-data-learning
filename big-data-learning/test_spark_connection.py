"""
测试本地PySpark连接到Docker中的Spark集群
"""
import os
import sys
from pyspark.sql import SparkSession
from pyspark import SparkConf

def test_spark_connection():
    """
    测试连接到Docker中的Spark集群
    """
    print("正在配置Spark连接...")
    
    # 配置Spark连接到Docker中的Spark集群
    # 根据Docker环境的资源配置进行调整
    conf = SparkConf() \
        .setAppName("LocalConnectionTest") \
        .setMaster("spark://localhost:7077") \
        .set("spark.sql.adaptive.enabled", "true") \
        .set("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .set("spark.driver.memory", "512m") \
        .set("spark.executor.memory", "512m") \
        .set("spark.executor.cores", "1") \
        .set("spark.driver.maxResultSize", "1g") \
        .set("spark.network.timeout", "120s")
    
    try:
        print("正在创建Spark会话...")
        spark = SparkSession.builder.config(conf=conf).getOrCreate()
        
        print("Spark会话创建成功!")
        print(f"Spark版本: {spark.version}")
        
        # 简单测试
        print("执行简单测试...")
        test_data = spark.range(100).filter("id > 10")
        count = test_data.count()
        print(f"测试查询结果: {count} 条记录")
        
        # 创建一个简单的DataFrame
        data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
        columns = ["Name", "Age"]
        df = spark.createDataFrame(data, columns)
        df.show()
        
        print("测试成功完成!")
        spark.stop()
        return True
        
    except Exception as e:
        print(f"连接失败: {e}")
        import traceback
        traceback.print_exc()
        print("请检查以下几点:")
        print("1. Docker中的Spark集群是否正在运行")
        print("2. 网络连接是否正常")
        print("3. 端口7077是否正确映射")
        return False

if __name__ == "__main__":
    print("开始测试本地PySpark连接到Docker中的Spark集群...")
    print(f"Python路径: {sys.executable}")
    print(f"Java版本信息:")
    os.system("java -version")
    
    success = test_spark_connection()
    if success:
        print("\n恭喜! 您已经成功配置了本地PySpark连接到Docker中的Spark集群。")
    else:
        print("\n连接失败，请检查配置。")