"""
通过正确网络配置连接到Docker中的Spark集群
"""
import os
import sys
import socket
from pyspark.sql import SparkSession
from pyspark import SparkConf

def get_local_ip():
    """
    获取本地IP地址
    """
    try:
        # 创建一个UDP socket来获取本地IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # 连接到一个远程地址（不会真正发送数据）
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def test_docker_cluster_connection():
    """
    测试连接到Docker中的Spark集群，使用正确的网络配置
    """
    print("=== 测试连接到Docker中的Spark集群（网络优化） ===")
    
    # 获取本地IP地址
    local_ip = get_local_ip()
    print(f"本地IP地址: {local_ip}")
    
    # 设置环境变量
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable
    
    try:
        # 创建连接到Docker集群的配置
        # 使用优化的网络和资源配置
        conf = SparkConf() \
            .setAppName("DockerClusterTestNetwork") \
            .setMaster("spark://localhost:7077") \
            .set("spark.driver.memory", "512m") \
            .set("spark.executor.memory", "512m") \
            .set("spark.executor.cores", "1") \
            .set("spark.cores.max", "2") \
            .set("spark.driver.host", local_ip) \
            .set("spark.driver.bindAddress", "0.0.0.0") \
            .set("spark.network.timeout", "240s") \
            .set("spark.executor.heartbeatInterval", "60s") \
            .set("spark.driver.port", "10000") \
            .set("spark.driver.blockManager.port", "10001") \
            .set("spark.ui.port", "4040")
        
        print("正在创建Spark会话...")
        print("配置信息:")
        for item in conf.getAll():
            print(f"  {item[0]}: {item[1]}")
        
        spark = SparkSession.builder.config(conf=conf).getOrCreate()
        print("✅ Spark会话创建成功!")
        
        # 测试基本操作
        print("\n--- 测试基本操作 ---")
        print(f"Spark版本: {spark.version}")
        print(f"应用ID: {spark.sparkContext.applicationId}")
        
        # 创建一个简单的DataFrame并进行非收集操作
        print("\n--- 测试非收集操作 ---")
        df = spark.range(100)
        count = df.count()  # count操作会在集群上执行但只返回一个数字
        print(f"DataFrame计数: {count}")
        
        # 进行过滤操作
        filtered_df = df.filter("id > 90")
        filtered_count = filtered_df.count()
        print(f"过滤后的计数: {filtered_count}")
        
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
    print("开始测试连接到Docker中的Spark集群（网络优化）...")
    success = test_docker_cluster_connection()
    
    if success:
        print("\n🎉 集群连接测试成功!")
        print("您现在可以使用本地PySpark连接到Docker中的Spark集群了。")
    else:
        print("\n❌ 集群连接测试失败。")
        print("可能的问题和解决方案:")
        print("1. 网络连接问题:")
        print("   - 确保Docker容器可以访问您的本地机器")
        print("   - 检查防火墙设置，确保端口10000和10001是开放的")
        print("2. 资源配置问题:")
        print("   - 检查Spark Master UI (http://localhost:8080) 确保有足够的资源")
        print("3. 版本兼容性问题:")
        print("   - 确保本地PySpark版本与Docker中的Spark版本兼容")

if __name__ == "__main__":
    main()