"""
优化资源配置以连接到Docker中的Spark集群
"""
import os
import sys
from pyspark.sql import SparkSession
from pyspark import SparkConf

def test_docker_cluster_connection():
    """
    测试连接到Docker中的Spark集群，使用优化的资源配置
    """
    print("=== 测试连接到Docker中的Spark集群（优化配置） ===")
    
    # 设置环境变量
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable
    
    try:
        # 创建连接到Docker集群的配置
        # 优化资源配置以适应集群情况
        conf = SparkConf() \
            .setAppName("DockerClusterTestOptimized") \
            .setMaster("spark://localhost:7077") \
            .set("spark.driver.memory", "512m") \
            .set("spark.executor.memory", "512m") \
            .set("spark.executor.cores", "1") \
            .set("spark.cores.max", "2") \
            .set("spark.driver.host", "127.0.0.1") \
            .set("spark.driver.bindAddress", "127.0.0.1") \
            .set("spark.network.timeout", "240s") \
            .set("spark.executor.heartbeatInterval", "60s")
        
        print("正在创建Spark会话...")
        spark = SparkSession.builder.config(conf=conf).getOrCreate()
        print("✅ Spark会话创建成功!")
        
        # 测试基本操作
        print("\n--- 测试基本操作 ---")
        print(f"Spark版本: {spark.version}")
        print(f"应用ID: {spark.sparkContext.applicationId}")
        
        # 创建一个简单的DataFrame并进行非收集操作
        print("\n--- 测试非收集操作 ---")
        df = spark.range(1000)
        count = df.count()  # count操作会在集群上执行但只返回一个数字
        print(f"DataFrame计数: {count}")
        
        # 进行过滤操作
        filtered_df = df.filter("id > 900")
        filtered_count = filtered_df.count()
        print(f"过滤后的计数: {filtered_count}")
        
        # 测试简单的聚合操作
        from pyspark.sql.functions import sum
        sum_result = df.agg(sum("id")).collect()
        print(f"ID总和: {sum_result[0][0]}")
        
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
    print("开始测试连接到Docker中的Spark集群（优化配置）...")
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