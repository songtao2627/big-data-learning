#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Spark连接测试脚本
用于验证Jupyter与Spark集群的连接
"""

from pyspark.sql import SparkSession
import sys

def test_spark_connection():
    """测试Spark连接"""
    try:
        # 创建SparkSession
        print("正在连接Spark集群...")
        spark = SparkSession.builder \
            .appName("SparkConnectionTest") \
            .master("spark://spark-master:7077") \
            .config("spark.sql.adaptive.enabled", "true") \
            .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
            .getOrCreate()

        # 测试连接
        print(f"✅ Spark版本: {spark.version}")
        print(f"✅ Spark应用ID: {spark.sparkContext.applicationId}")
        print(f"✅ Spark UI地址: {spark.sparkContext.uiWebUrl}")
        
        # 创建测试DataFrame
        print("\n创建测试DataFrame...")
        test_data = [("张三", 25, "北京"), ("李四", 30, "上海"), ("王五", 35, "广州")]
        columns = ["姓名", "年龄", "城市"]
        df = spark.createDataFrame(test_data, columns)
        
        print("测试DataFrame内容:")
        df.show()
        
        print(f"DataFrame行数: {df.count()}")
        print(f"DataFrame列数: {len(df.columns)}")
        
        # 简单的数据操作测试
        print("\n执行简单的数据操作...")
        avg_age = df.agg({"年龄": "avg"}).collect()[0][0]
        print(f"平均年龄: {avg_age:.1f}")
        
        # 停止SparkSession
        spark.stop()
        print("\n🎉 Spark连接测试成功！")
        return True
        
    except Exception as e:
        print(f"❌ Spark连接测试失败: {str(e)}")
        return False

if __name__ == "__main__":
    test_spark_connection()
