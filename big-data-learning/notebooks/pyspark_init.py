from pyspark.sql import SparkSession
def create_spark_session(app_name="SparkLearning"):
    spark = SparkSession.builder.appName(app_name).master("spark://spark-master:7077").config("spark.executor.memory", "1g").config("spark.driver.memory", "1g").getOrCreate()
    spark.sparkContext.setLogLevel("WARN")
    return spark
