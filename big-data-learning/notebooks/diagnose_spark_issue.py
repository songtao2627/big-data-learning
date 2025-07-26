#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Spark 问题诊断脚本
帮助理解 df.show() 卡住的原因
"""

from pyspark.sql import SparkSession
import time
import sys

def diagnose_spark_connection():
    """逐步诊断 Spark 连接问题"""
    
    print("=== Spark 连接诊断开始 ===\n")
    
    # 步骤1: 创建 SparkSession（这一步通常很快）
    print("步骤1: 创建 SparkSession...")
    start_time = time.time()
    
    try:
        spark = SparkSession.builder \
            .appName("SparkDiagnosis") \
            .master("spark://spark-master:7077") \
            .config("spark.driver.memory", "512m") \
            .config("spark.executor.memory", "1g") \
            .config("spark.executor.cores", "1") \
            .config("spark.sql.adaptive.enabled", "true") \
            .getOrCreate()
        
        session_time = time.time() - start_time
        print(f"✅ SparkSession 创建成功 (耗时: {session_time:.2f}秒)")
        print(f"   Spark版本: {spark.version}")
        print(f"   应用ID: {spark.sparkContext.applicationId}")
        
    except Exception as e:
        print(f"❌ SparkSession 创建失败: {e}")
        return False
    
    # 步骤2: 检查 SparkContext 状态
    print(f"\n步骤2: 检查 SparkContext 状态...")
    sc = spark.sparkContext
    print(f"   状态: {sc.statusTracker().getExecutorInfos()}")
    print(f"   默认并行度: {sc.defaultParallelism}")
    
    # 步骤3: 创建简单的 DataFrame（这一步也很快，因为是懒执行）
    print(f"\n步骤3: 创建 DataFrame...")
    start_time = time.time()
    
    test_data = [("测试", 1), ("数据", 2)]
    columns = ["文本", "数字"]
    df = spark.createDataFrame(test_data, columns)
    
    create_time = time.time() - start_time
    print(f"✅ DataFrame 创建成功 (耗时: {create_time:.2f}秒)")
    print("   注意: 这是懒执行，还没有实际计算")
    
    # 步骤4: 执行第一个 Action（这里可能会卡住）
    print(f"\n步骤4: 执行第一个 Action (df.count())...")
    print("   这一步会触发 executor 的实际启动和任务分配")
    start_time = time.time()
    
    try:
        # 设置较短的超时来快速发现问题
        spark.conf.set("spark.network.timeout", "60s")
        spark.conf.set("spark.executor.heartbeatInterval", "10s")
        
        count = df.count()
        action_time = time.time() - start_time
        print(f"✅ 第一个 Action 执行成功 (耗时: {action_time:.2f}秒)")
        print(f"   数据行数: {count}")
        
        # 如果 count() 成功，show() 应该也会成功
        print(f"\n步骤5: 执行 df.show()...")
        start_time = time.time()
        df.show()
        show_time = time.time() - start_time
        print(f"✅ df.show() 执行成功 (耗时: {show_time:.2f}秒)")
        
    except Exception as e:
        action_time = time.time() - start_time
        print(f"❌ Action 执行失败 (耗时: {action_time:.2f}秒)")
        print(f"   错误信息: {e}")
        print(f"   这就是你的脚本卡住的原因！")
        
        # 提供解决建议
        print(f"\n🔧 可能的解决方案:")
        print(f"   1. 检查 executor 是否成功启动")
        print(f"   2. 增加网络超时时间")
        print(f"   3. 减少资源需求")
        print(f"   4. 检查 Docker 容器资源限制")
        
        return False
    
    finally:
        print(f"\n清理资源...")
        spark.stop()
    
    print(f"\n=== 诊断完成 ===")
    return True

if __name__ == "__main__":
    diagnose_spark_connection()