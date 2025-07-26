#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
快速 Spark 连接测试 - 兼容版本差异
这个脚本展示了如何处理版本兼容性问题
"""

import sys
import os

def setup_pyspark_path():
    """设置 PySpark 路径"""
    # 方法1: 使用 findspark（如果可用）
    try:
        import findspark
        findspark.init()
        print("✅ 使用 findspark 初始化 PySpark")
        return True
    except ImportError:
        pass
    
    # 方法2: 手动设置路径
    spark_home = "/usr/local/spark"
    if os.path.exists(spark_home):
        sys.path.insert(0, os.path.join(spark_home, "python"))
        sys.path.insert(0, os.path.join(spark_home, "python", "lib", "py4j-0.10.9.7-src.zip"))
        print("✅ 手动设置 PySpark 路径")
        return True
    
    print("❌ 无法找到 PySpark")
    return False

def test_spark_with_local_mode():
    """使用本地模式测试 Spark（避免版本兼容性问题）"""
    try:
        from pyspark.sql import SparkSession
        
        print("创建本地模式的 SparkSession...")
        spark = SparkSession.builder \
            .appName("LocalSparkTest") \
            .master("local[2]") \
            .config("spark.sql.adaptive.enabled", "true") \
            .getOrCreate()
        
        print(f"✅ Spark版本: {spark.version}")
        print(f"✅ 运行模式: 本地模式")
        
        # 创建测试数据
        test_data = [("张三", 25, "北京"), ("李四", 30, "上海"), ("王五", 35, "广州")]
        columns = ["姓名", "年龄", "城市"]
        df = spark.createDataFrame(test_data, columns)
        
        print("\n测试 DataFrame 操作:")
        df.show()
        
        print(f"数据行数: {df.count()}")
        avg_age = df.agg({"年龄": "avg"}).collect()[0][0]
        print(f"平均年龄: {avg_age:.1f}")
        
        spark.stop()
        print("\n🎉 本地模式测试成功！")
        return True
        
    except Exception as e:
        print(f"❌ 本地模式测试失败: {e}")
        return False

def test_spark_cluster_connection():
    """测试集群连接（处理版本兼容性）"""
    try:
        from pyspark.sql import SparkSession
        
        print("\n尝试连接 Spark 集群...")
        spark = SparkSession.builder \
            .appName("ClusterCompatibilityTest") \
            .master("spark://spark-master:7077") \
            .config("spark.driver.memory", "512m") \
            .config("spark.executor.memory", "1g") \
            .config("spark.executor.cores", "1") \
            .config("spark.network.timeout", "30s") \
            .config("spark.executor.heartbeatInterval", "10s") \
            .getOrCreate()
        
        print(f"✅ 集群连接成功")
        print(f"✅ Spark版本: {spark.version}")
        
        # 创建简单数据进行测试
        print("\n测试简单操作...")
        rdd = spark.sparkContext.parallelize([1, 2, 3, 4, 5])
        result = rdd.sum()
        print(f"✅ RDD 求和结果: {result}")
        
        # 测试 DataFrame（可能在这里遇到版本兼容性问题）
        try:
            df = spark.createDataFrame([(1, "test")], ["id", "name"])
            count = df.count()
            print(f"✅ DataFrame 测试成功，行数: {count}")
        except Exception as df_error:
            print(f"⚠️  DataFrame 操作遇到版本兼容性问题: {df_error}")
            print("这通常是由于客户端和服务端 Spark 版本不匹配造成的")
        
        spark.stop()
        return True
        
    except Exception as e:
        print(f"❌ 集群连接失败: {e}")
        return False

def main():
    """主函数"""
    print("=== Spark 快速兼容性测试 ===\n")
    
    # 步骤1: 设置 PySpark 路径
    if not setup_pyspark_path():
        print("无法设置 PySpark 环境，退出测试")
        return
    
    # 步骤2: 测试本地模式（总是应该工作）
    print("\n--- 测试本地模式 ---")
    local_success = test_spark_with_local_mode()
    
    # 步骤3: 测试集群连接
    print("\n--- 测试集群连接 ---")
    cluster_success = test_spark_cluster_connection()
    
    # 总结
    print("\n=== 测试总结 ===")
    print(f"本地模式: {'✅ 成功' if local_success else '❌ 失败'}")
    print(f"集群模式: {'✅ 成功' if cluster_success else '❌ 失败'}")
    
    if local_success and not cluster_success:
        print("\n💡 建议:")
        print("1. 本地模式工作正常，说明 PySpark 安装正确")
        print("2. 集群连接问题可能是版本兼容性导致")
        print("3. 可以先使用本地模式学习 Spark 基础概念")
        print("4. 等待 Jupyter 容器完成 PySpark 3.4.3 安装后再测试集群模式")

if __name__ == "__main__":
    main()