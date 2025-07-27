"""
修复本地PySpark环境的脚本
"""
import os
import sys
import subprocess
from pyspark.sql import SparkSession
from pyspark import SparkConf

def diagnose_environment():
    """
    诊断当前环境
    """
    print("=== 环境诊断 ===")
    print(f"Python executable: {sys.executable}")
    print(f"Python version: {sys.version}")
    
    try:
        import pyspark
        print(f"PySpark version: {pyspark.__version__}")
        print(f"PySpark location: {pyspark.__file__}")
    except Exception as e:
        print(f"无法导入PySpark: {e}")
    
    # 检查Java版本
    try:
        result = subprocess.run(["java", "-version"], capture_output=True, text=True)
        print("Java version info:")
        print(result.stderr)
    except Exception as e:
        print(f"无法检查Java版本: {e}")

def fix_environment_variables():
    """
    修复环境变量
    """
    print("\n=== 修复环境变量 ===")
    
    # 设置PySpark Python路径
    python_exe = sys.executable
    os.environ['PYSPARK_PYTHON'] = python_exe
    os.environ['PYSPARK_DRIVER_PYTHON'] = python_exe
    
    print(f"设置 PYSPARK_PYTHON = {python_exe}")
    print(f"设置 PYSPARK_DRIVER_PYTHON = {python_exe}")
    
    # 设置其他可能需要的环境变量
    os.environ['SPARK_LOCAL_IP'] = '127.0.0.1'
    print("设置 SPARK_LOCAL_IP = 127.0.0.1")

def test_local_spark_session():
    """
    测试本地Spark会话
    """
    print("\n=== 测试本地Spark会话 ===")
    
    try:
        # 配置本地Spark会话
        conf = SparkConf() \
            .setAppName("FixEnvTest") \
            .setMaster("local[2]") \
            .set("spark.driver.memory", "512m") \
            .set("spark.executor.memory", "512m") \
            .set("spark.sql.adaptive.enabled", "true") \
            .set("spark.sql.adaptive.coalescePartitions.enabled", "true") \
            .set("spark.driver.host", "127.0.0.1") \
            .set("spark.driver.bindAddress", "127.0.0.1")
        
        spark = SparkSession.builder.config(conf=conf).getOrCreate()
        print("Spark会话创建成功!")
        print(f"Spark版本: {spark.version}")
        
        # 简单测试
        print("执行简单测试...")
        df = spark.range(5)
        result = df.collect()
        print(f"收集到的结果: {result}")
        
        # 创建DataFrame测试
        data = [("Alice", 25), ("Bob", 30)]
        columns = ["Name", "Age"]
        df = spark.createDataFrame(data, columns)
        df.show()
        
        spark.stop()
        print("本地Spark测试成功!")
        return True
        
    except Exception as e:
        print(f"本地Spark测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """
    主函数
    """
    print("开始修复本地PySpark环境...")
    
    # 诊断环境
    diagnose_environment()
    
    # 修复环境变量
    fix_environment_variables()
    
    # 测试本地Spark会话
    success = test_local_spark_session()
    
    if success:
        print("\n✅ 本地PySpark环境修复成功!")
        print("\n建议解决方案:")
        print("1. 使用本地模式进行开发和测试 (master='local[*]')")
        print("2. 确保Java版本与PySpark版本兼容")
        print("3. 设置正确的环境变量:")
        print("   - PYSPARK_PYTHON: 指向正确的Python解释器")
        print("   - PYSPARK_DRIVER_PYTHON: 指向正确的Python解释器")
        print("   - SPARK_LOCAL_IP: 设置为127.0.0.1")
    else:
        print("\n❌ 本地PySpark环境修复失败!")
        print("\n建议采取以下步骤:")
        print("1. 升级Java到11或更高版本")
        print("2. 或者降级PySpark到与Java 8兼容的版本 (如3.3.x)")
        print("3. 确保环境变量设置正确")
        print("4. 检查防火墙设置")

if __name__ == "__main__":
    main()