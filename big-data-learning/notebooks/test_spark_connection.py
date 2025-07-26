from pyspark.sql import SparkSession

# 创建SparkSession
spark = SparkSession.builder \
    .appName("SparkConnectionTest") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

# 测试连接
print("Spark版本:", spark.version)
print("Spark应用ID:", spark.sparkContext.applicationId)
print("Spark UI地址:", spark.sparkContext.uiWebUrl)

# 创建测试DataFrame
test_data = [("张三", 25), ("李四", 30), ("王五", 35)]
df = spark.createDataFrame(test_data, ["name", "age"])
print("测试DataFrame:")
df.show()

# 停止SparkSession
spark.stop()
