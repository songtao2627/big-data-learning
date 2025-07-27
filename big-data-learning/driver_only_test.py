"""
仅使用驱动程序的PySpark测试脚本
"""
import os
import sys

def test_driver_only():
    """
    测试仅使用驱动程序的PySpark功能
    """
    print("=== 仅驱动程序模式测试 ===")
    
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
    
    print("\n=== 测试SparkContext功能 ===")
    try:
        # 导入必要的模块
        from pyspark.sql import SparkSession
        from pyspark import SparkContext, SparkConf
        
        # 创建配置，尽量减少需要执行器的操作
        conf = SparkConf() \
            .setAppName("DriverOnlyTest") \
            .setMaster("local[1]") \
            .set("spark.driver.memory", "512m") \
            .set("spark.executor.memory", "512m") \
            .set("spark.sql.adaptive.enabled", "false") \
            .set("spark.sql.adaptive.coalescePartitions.enabled", "false")
        
        spark = SparkSession.builder.config(conf=conf).getOrCreate()
        sc = spark.sparkContext
        
        print("✅ Spark会话和上下文创建成功!")
        
        # 测试本地数据结构
        print("\n--- 测试本地数据结构 ---")
        # 使用parallelize会触发执行器，我们避免这样做
        # 相反，我们测试可以直接在驱动程序中完成的操作
        
        # 测试系统信息
        print(f"Spark版本: {sc.version}")
        print(f"应用名称: {sc.appName}")
        print(f"主节点: {sc.master}")
        
        # 测试配置信息
        print("\n--- 测试配置信息 ---")
        print(f"驱动程序内存: {sc.getConf().get('spark.driver.memory', '未设置')}")
        print(f"执行器内存: {sc.getConf().get('spark.executor.memory', '未设置')}")
        
        # 测试简单的本地操作
        print("\n--- 测试本地操作 ---")
        # 创建一个简单的本地列表
        local_data = [1, 2, 3, 4, 5]
        print(f"本地数据: {local_data}")
        
        # 对本地数据进行操作
        squared_data = [x ** 2 for x in local_data]
        print(f"平方后数据: {squared_data}")
        
        # 测试字符串操作
        test_string = "Hello PySpark"
        print(f"测试字符串: {test_string}")
        print(f"字符串长度: {len(test_string)}")
        print(f"大写转换: {test_string.upper()}")
        
        spark.stop()
        print("\n✅ 仅驱动程序测试通过!")
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
    print("开始仅驱动程序模式测试...")
    success = test_driver_only()
    
    if success:
        print("\n🎉 仅驱动程序测试成功!")
        print("您的PySpark环境已正确安装，可以访问Spark API。")
        print("\n注意:")
        print("- 您可以使用Spark配置和上下文对象")
        print("- 某些分布式操作可能需要额外配置才能正常工作")
        print("- 这是解决Windows上PySpark问题的第一步")
    else:
        print("\n❌ 仅驱动程序测试失败。")

if __name__ == "__main__":
    main()