"""
测试连接到Docker中的Spark集群
"""
import os
import sys
from pyspark.sql import SparkSession
from pyspark import SparkConf

def test_docker_cluster_connection():
    """
    测试连接到Docker中的Spark集群
    """
    print("=== 测试连接到Docker中的Spark集群 ===")
    
    # 设置环境变量
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable
    
    try:
        # 创建连接到Docker集群的配置
        conf = SparkConf() \
            .setAppName("DockerClusterTest") \
            .setMaster("spark://localhost:7077") \
            .set("spark.driver.memory", "512m") \
            .set("spark.executor.memory", "512m") \
            .set("spark.executor.cores", "1") \
            .set("spark.driver.host", "127.0.0.1") \
            .set("spark.driver.bindAddress", "127.0.0.1")
        
        print("正在创建Spark会话...")
        spark = SparkSession.builder.config(conf=conf).getOrCreate()
        print("✅ Spark会话创建成功!")
        
        # 测试基本操作
        print("\n--- 测试基本操作 ---")
        print(f"Spark版本: {spark.version}")
        print(f"应用ID: {spark.sparkContext.applicationId}")
        
        # 创建一个简单的DataFrame
        print("\n--- 创建和收集DataFrame ---")
        df = spark.range(10)
        count = df.count()
        print(f"DataFrame计数: {count}")
        
        # 收集部分数据
        data = df.take(5)
        print(f"前5条数据: {[row[0] for row in data]}")
        
        spark.stop()
        print("\n✅ 成功连接到Docker集群并完成测试!")
        return True
        
    except Exception as e:
        print(f"❌ 连接失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """
    主函数
    """
    print("开始测试连接到Docker中的Spark集群...")
    success = test_docker_cluster_connection()
    
    if success:
        print("\n🎉 集群连接测试成功!")
        print("您现在可以使用本地PySpark连接到Docker中的Spark集群了。")
    else:
        print("\n❌ 集群连接测试失败。")
        print("请检查以下几点:")
        print("1. Docker中的Spark集群是否正在运行")
        print("2. 端口7077是否正确映射")
        print("3. 网络连接是否正常")
        print("4. 防火墙是否阻止了连接")

if __name__ == "__main__":
    main()