"""
PySpark配置模块
用于在Jupyter Notebook中自动配置PySpark环境
"""

import os
import sys
import findspark

# 初始化Spark环境
findspark.init()

# 导入PySpark相关模块
from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession

# 配置Spark
def configure_spark(app_name="SparkLearningApp", master="spark://spark-master:7077"):
    """
    配置并返回SparkSession
    
    参数:
        app_name: Spark应用名称
        master: Spark主节点URL
    
    返回:
        配置好的SparkSession实例
    """
    # 创建SparkConf
    conf = SparkConf()
    conf.setAppName(app_name)
    conf.setMaster(master)
    
    # 设置其他配置
    conf.set("spark.executor.memory", "512m")
    conf.set("spark.driver.memory", "1g")
    conf.set("spark.executor.cores", "1")
    conf.set("spark.sql.execution.arrow.pyspark.enabled", "true")
    conf.set("spark.ui.port", "4040")
    
    # 创建SparkSession
    spark = SparkSession.builder \
        .config(conf=conf) \
        .getOrCreate()
    
    return spark

# 默认SparkSession
spark = configure_spark()

# 打印Spark信息
print("PySpark已配置:")
print(f"  - Spark版本: {spark.version}")
print(f"  - 应用ID: {spark.sparkContext.applicationId}")
print(f"  - Spark UI: {spark.sparkContext.uiWebUrl}")

# 导出常用函数
def load_csv(path, header=True, inferSchema=True):
    """
    加载CSV文件为DataFrame
    """
    return spark.read.option("header", header).option("inferSchema", inferSchema).csv(path)

def load_json(path):
    """
    加载JSON文件为DataFrame
    """
    return spark.read.json(path)

def load_parquet(path):
    """
    加载Parquet文件为DataFrame
    """
    return spark.read.parquet(path)

def show_schema(df):
    """
    以树形结构显示DataFrame的schema
    """
    return df.printSchema()

def describe_df(df):
    """
    显示DataFrame的详细信息
    """
    print(f"DataFrame信息:")
    print(f"  - 列数: {len(df.columns)}")
    print(f"  - 行数: {df.count()}")
    print(f"  - 分区数: {df.rdd.getNumPartitions()}")
    print(f"  - Schema:")
    df.printSchema()
    print(f"  - 示例数据:")
    df.show(5, truncate=False)
    
    # 显示统计信息
    print(f"  - 统计信息:")
    df.describe().show()

# 设置默认日志级别
spark.sparkContext.setLogLevel("WARN")