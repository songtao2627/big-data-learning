"""
本地模式测试脚本，用于验证PySpark是否正常工作
"""
import os
import sys
from pyspark.sql import SparkSession

def local_mode_test():
    """
    本地模式测试
    """
    try:
        print("正在创建本地Spark会话...")
        # 使用本地模式创建Spark会话
        spark = SparkSession.builder \
            .appName("LocalModeTest") \
            .master("local[*]") \
            .config("spark.driver.memory", "512m") \
            .config("spark.executor.memory", "512m") \
            .getOrCreate()
        
        print("本地Spark会话创建成功!")
        print(f"Spark版本: {spark.version}")
        
        # 简单测试
        print("执行简单测试...")
        df = spark.range(10)
        result = df.filter("id > 5").collect()
        print(f"过滤结果: {result}")
        
        # 创建DataFrame测试
        data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
        columns = ["Name", "Age"]
        df = spark.createDataFrame(data, columns)
        df.show()
        
        print("本地模式测试成功完成!")
        spark.stop()
        return True
        
    except Exception as e:
        print(f"本地模式测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("开始本地模式测试...")
    print(f"Python路径: {sys.executable}")
    
    success = local_mode_test()
    if success:
        print("\n本地模式测试成功! PySpark环境正常工作。")
    else:
        print("\n本地模式测试失败，请检查PySpark安装。")