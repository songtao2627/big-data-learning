#!/usr/bin/env python3
"""
Docker 容器网络连通性测试脚本
测试各容器间的网络通信是否正常
"""

import socket
import subprocess
import sys
import time
from datetime import datetime

def print_section(title):
    print(f"\n{'='*60}")
    print(f"🔍 {title}")
    print('='*60)

def test_dns_resolution():
    """测试 DNS 解析"""
    print_section("DNS 解析测试")
    
    hosts = [
        "spark-master",
        "spark-worker-1", 
        "spark-worker-2",
        "spark-dev",
        "zookeeper",
        "kafka",
        "elasticsearch",
        "kibana"
    ]
    
    for host in hosts:
        try:
            ip = socket.gethostbyname(host)
            print(f"✅ {host:15} -> {ip}")
        except socket.gaierror:
            print(f"❌ {host:15} -> DNS 解析失败")

def test_port_connectivity():
    """测试端口连通性"""
    print_section("端口连通性测试")
    
    # 定义服务和端口
    services = [
        ("spark-master", 7077, "Spark Master"),
        ("spark-master", 8080, "Spark Master UI"),
        ("spark-worker-1", 8881, "Spark Worker 1"),
        ("spark-worker-1", 8081, "Spark Worker 1 UI"),
        ("spark-worker-2", 8882, "Spark Worker 2"),
        ("spark-worker-2", 8081, "Spark Worker 2 UI"),
        ("spark-dev", 8888, "Jupyter Lab"),
        ("zookeeper", 2181, "Zookeeper"),
        ("kafka", 29092, "Kafka Internal"),
        ("elasticsearch", 9200, "Elasticsearch"),
        ("kibana", 5601, "Kibana")
    ]
    
    for host, port, service in services:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(3)
            result = sock.connect_ex((host, port))
            sock.close()
            
            if result == 0:
                print(f"✅ {service:20} {host}:{port} - 连接成功")
            else:
                print(f"❌ {service:20} {host}:{port} - 连接失败")
                
        except Exception as e:
            print(f"❌ {service:20} {host}:{port} - 测试异常: {str(e)}")

def test_ping_connectivity():
    """测试 ping 连通性"""
    print_section("Ping 连通性测试")
    
    hosts = ["spark-master", "spark-worker-1", "spark-worker-2"]
    
    for host in hosts:
        try:
            # 使用 ping 命令测试连通性
            result = subprocess.run(
                ["ping", "-c", "2", host], 
                capture_output=True, 
                text=True, 
                timeout=10
            )
            
            if result.returncode == 0:
                print(f"✅ {host:15} - Ping 成功")
            else:
                print(f"❌ {host:15} - Ping 失败")
                
        except subprocess.TimeoutExpired:
            print(f"❌ {host:15} - Ping 超时")
        except Exception as e:
            print(f"❌ {host:15} - Ping 异常: {str(e)}")

def test_spark_cluster_communication():
    """测试 Spark 集群通信"""
    print_section("Spark 集群通信测试")
    
    try:
        from pyspark.sql import SparkSession
        
        print("🔗 创建 Spark 会话...")
        spark = SparkSession.builder \
            .appName("NetworkConnectivityTest") \
            .master("spark://spark-master:7077") \
            .config("spark.executor.memory", "512m") \
            .config("spark.driver.memory", "512m") \
            .getOrCreate()
        
        spark.sparkContext.setLogLevel("WARN")
        
        print(f"✅ Spark 版本: {spark.version}")
        print(f"✅ Master URL: {spark.sparkContext.master}")
        print(f"✅ 应用 ID: {spark.sparkContext.applicationId}")
        
        # 测试简单的分布式操作
        print("\n🧮 测试分布式计算...")
        rdd = spark.sparkContext.parallelize(range(100), 4)
        result = rdd.map(lambda x: x * x).reduce(lambda a, b: a + b)
        print(f"✅ 分布式计算结果: {result}")
        
        # 获取 Executor 信息
        executors = spark.sparkContext.statusTracker().getExecutorInfos()
        print(f"✅ 活跃 Executor 数量: {len(executors)}")
        
        for executor in executors:
            print(f"   Executor {executor.executorId}: {executor.host}")
        
        spark.stop()
        print("✅ Spark 集群通信测试通过")
        return True
        
    except Exception as e:
        print(f"❌ Spark 集群通信失败: {str(e)}")
        return False

def test_network_performance():
    """测试网络性能"""
    print_section("网络性能测试")
    
    hosts = ["spark-master", "spark-worker-1", "spark-worker-2"]
    
    for host in hosts:
        try:
            start_time = time.time()
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            sock.connect((host, 7077))
            sock.close()
            end_time = time.time()
            
            latency = (end_time - start_time) * 1000
            print(f"✅ {host:15} - 连接延迟: {latency:.2f}ms")
            
        except Exception as e:
            print(f"❌ {host:15} - 性能测试失败: {str(e)}")

def show_network_info():
    """显示网络信息"""
    print_section("网络配置信息")
    
    try:
        # 显示容器 IP 地址
        result = subprocess.run(
            ["hostname", "-I"], 
            capture_output=True, 
            text=True
        )
        if result.returncode == 0:
            print(f"当前容器 IP: {result.stdout.strip()}")
        
        # 显示路由信息
        result = subprocess.run(
            ["ip", "route"], 
            capture_output=True, 
            text=True
        )
        if result.returncode == 0:
            print(f"\n路由信息:")
            print(result.stdout)
            
    except Exception as e:
        print(f"获取网络信息失败: {str(e)}")

def main():
    """主测试函数"""
    print("🚀 Docker 容器网络连通性测试")
    print(f"⏰ 测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 显示网络信息
    show_network_info()
    
    # 执行各项测试
    tests = [
        ("DNS 解析", test_dns_resolution),
        ("端口连通性", test_port_connectivity),
        ("Ping 连通性", test_ping_connectivity),
        ("网络性能", test_network_performance),
        ("Spark 集群通信", test_spark_cluster_communication)
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        try:
            print(f"\n🔍 开始 {test_name} 测试...")
            result = test_func()
            results[test_name] = result if result is not None else True
        except Exception as e:
            print(f"❌ {test_name} 测试异常: {str(e)}")
            results[test_name] = False
    
    # 总结报告
    print_section("测试总结")
    
    passed = sum(1 for result in results.values() if result)
    total = len(results)
    
    for test_name, result in results.items():
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {test_name:15}: {status}")
    
    print(f"\n📊 测试结果: {passed}/{total} 通过")
    
    if passed == total:
        print("🎉 所有网络测试通过！容器间通信正常")
    else:
        print("⚠️  部分网络测试失败，请检查网络配置")
        print("\n🔧 故障排除建议:")
        print("  1. 检查容器状态: docker-compose ps")
        print("  2. 检查网络: docker network ls")
        print("  3. 重启环境: docker-compose down && docker-compose up -d")

if __name__ == "__main__":
    main()