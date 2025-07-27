"""
简化版的PySpark测试脚本
"""
import os
import sys

def test_basic_pyspark():
    """
    测试基本的PySpark功能
    """
    print("=== 简化版PySpark测试 ===")
    
    # 检查PySpark版本
    try:
        import pyspark
        print(f"PySpark版本: {pyspark.__version__}")
    except ImportError:
        print("❌ 无法导入PySpark")
        return False
    
    # 设置环境变量
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable
    
    print("\n=== 测试基本功能 ===")
    try:
        # 导入必要的模块
        from pyspark.sql import SparkSession
        
        # 创建最简单的Spark会话
        spark = SparkSession.builder \
            .appName("SimpleTest") \
            .master("local[1]") \
            .config("spark.driver.memory", "512m") \
            .config("spark.executor.memory", "512m") \
            .config("spark.sql.adaptive.enabled", "false") \
            .getOrCreate()
        
        print("✅ Spark会话创建成功!")
        
        # 测试基本的RDD操作
        print("\n--- 测试RDD操作 ---")
        rdd = spark.sparkContext.parallelize([1, 2, 3, 4, 5])
        result = rdd.map(lambda x: x * 2).collect()
        print(f"RDD映射结果: {result}")
        
        # 测试基本的DataFrame操作
        print("\n--- 测试DataFrame基本操作 ---")
        df = spark.range(5)
        count = df.count()
        print(f"DataFrame计数: {count}")
        
        # 收集数据
        collected = df.collect()
        print(f"收集的数据: {[r[0] for r in collected]}")
        
        spark.stop()
        print("\n✅ 基本功能测试通过!")
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
    print("开始简化版PySpark测试...")
    success = test_basic_pyspark()
    
    if success:
        print("\n🎉 简化版测试成功!")
        print("您的PySpark环境已经可以执行基本操作。")
        print("\n注意:")
        print("- DataFrame的show()方法在Windows上可能仍有问题")
        print("- 复杂的分布式操作可能需要额外配置")
        print("- 但基本的RDD和DataFrame操作应该可以正常工作")
    else:
        print("\n❌ 简化版测试失败。")

if __name__ == "__main__":
    main()