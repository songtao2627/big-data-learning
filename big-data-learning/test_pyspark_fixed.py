"""
测试修复后的PySpark环境
"""
import os
import sys
from pyspark.sql import SparkSession
from pyspark import SparkConf

def test_pyspark_environment():
    """
    测试PySpark环境是否正常工作
    """
    print("=== 测试修复后的PySpark环境 ===")
    
    # 检查PySpark版本
    try:
        import pyspark
        print(f"PySpark版本: {pyspark.__version__}")
    except ImportError:
        print("❌ 无法导入PySpark")
        return False
    
    # 检查Java版本
    try:
        import subprocess
        result = subprocess.run(["java", "-version"], capture_output=True, text=True)
        print("Java版本信息:")
        print(result.stderr.strip())
    except Exception as e:
        print(f"无法检查Java版本: {e}")
    
    # 设置环境变量
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable
    
    print("\n=== 测试本地Spark会话 ===")
    try:
        # 创建本地Spark会话
        conf = SparkConf() \
            .setAppName("TestFixedEnvironment") \
            .setMaster("local[2]") \
            .set("spark.driver.memory", "512m") \
            .set("spark.executor.memory", "512m")
        
        spark = SparkSession.builder.config(conf=conf).getOrCreate()
        print("✅ Spark会话创建成功!")
        
        # 测试基本操作
        print("\n--- 测试基本操作 ---")
        df = spark.range(10)
        result = df.filter("id > 5").collect()
        print(f"过滤结果: {[r.id for r in result]}")
        
        # 测试DataFrame操作
        print("\n--- 测试DataFrame操作 ---")
        data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
        columns = ["Name", "Age"]
        df = spark.createDataFrame(data, columns)
        df.show()
        
        # 测试SQL操作
        print("\n--- 测试SQL操作 ---")
        df.createOrReplaceTempView("people")
        sql_result = spark.sql("SELECT * FROM people WHERE Age > 25").collect()
        print(f"年龄大于25的人: {[r.Name for r in sql_result]}")
        
        spark.stop()
        print("\n✅ 所有测试通过! 本地PySpark环境已成功修复。")
        return True
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """
    主函数
    """
    print("开始测试修复后的PySpark环境...")
    success = test_pyspark_environment()
    
    if success:
        print("\n🎉 环境修复成功!")
        print("\n现在您可以:")
        print("1. 使用本地模式进行Spark开发和测试")
        print("2. 连接到Docker中的Spark集群 (需要网络配置)")
        print("3. 在Jupyter Notebook中使用PySpark")
    else:
        print("\n❌ 环境修复失败，请检查配置。")

if __name__ == "__main__":
    main()