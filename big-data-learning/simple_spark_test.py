"""
简单的Spark连接测试脚本
"""
import os
import sys
from pyspark.sql import SparkSession
from pyspark import SparkConf

def simple_spark_test():
    """
    简单的Spark连接测试
    """
    print("正在配置Spark连接...")
    
    # 配置Spark连接到Docker中的Spark集群
    conf = SparkConf() \
        .setAppName("SimpleTest") \
        .setMaster("spark://localhost:7077") \
        .set("spark.driver.memory", "512m") \
        .set("spark.executor.memory", "512m") \
        .set("spark.executor.cores", "1") \
        .set("spark.network.timeout", "60s")
    
    try:
        print("正在创建Spark会话...")
        spark = SparkSession.builder.config(conf=conf).getOrCreate()
        
        print("Spark会话创建成功!")
        print(f"Spark版本: {spark.version}")
        
        # 简单测试 - 创建一个小型DataFrame并执行操作
        print("执行简单测试...")
        df = spark.range(5)
        result = df.collect()
        print(f"收集到的结果: {result}")
        
        print("测试成功完成!")
        spark.stop()
        return True
        
    except Exception as e:
        print(f"连接失败: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("开始简单测试本地PySpark连接到Docker中的Spark集群...")
    print(f"Python路径: {sys.executable}")
    
    success = simple_spark_test()
    if success:
        print("\n恭喜! 您已经成功配置了本地PySpark连接到Docker中的Spark集群。")
    else:
        print("\n连接失败，请检查配置。")