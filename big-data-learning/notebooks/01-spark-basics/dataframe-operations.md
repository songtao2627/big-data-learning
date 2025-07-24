# Spark DataFrame操作

本文档介绍Spark的DataFrame API，这是一个更高级的数据处理抽象，类似于关系型数据库中的表或R/Python中的DataFrame。

## 什么是DataFrame？

DataFrame是一个分布式的数据集合，组织成命名的列。它概念上等同于关系型数据库中的表或R/Python中的DataFrame，但具有更丰富的优化功能。DataFrame可以从多种数据源构建，如结构化数据文件、Hive表、外部数据库或现有RDD。

DataFrame的主要优点：
- **结构化数据处理**：提供类似SQL的操作
- **优化执行**：通过Catalyst优化器自动优化查询
- **更好的性能**：比RDD更高效的内存使用和执行计划
- **易用性**：提供高级API，减少代码量

## 1. 创建SparkSession

与RDD一样，我们首先需要创建一个SparkSession：

```python
from pyspark.sql import SparkSession

# 创建SparkSession
spark = SparkSession.builder \
    .appName("DataFrame操作") \
    .getOrCreate()

# 显示Spark版本
print(f"Spark版本: {spark.version}")
```

## 2. 创建DataFrame

有多种方法可以创建DataFrame：

### 2.1 从结构化数据文件创建

```python
# 从CSV文件创建DataFrame
sales_df = spark.read.option("header", "true") \
                    .option("inferSchema", "true") \
                    .csv("/home/jovyan/data/sample/sales_data.csv")

# 显示DataFrame内容
print("销售数据:")
sales_df.show()

# 显示Schema
print("销售数据Schema:")
sales_df.printSchema()

# 从JSON文件创建DataFrame
user_df = spark.read.json("/home/jovyan/data/sample/user_behavior.json")

print("用户行为数据:")
user_df.show()
```

### 2.2 从Python对象创建

```python
# 从列表创建DataFrame
data = [("张三", 25), ("李四", 30), ("王五", 35), ("赵六", 40)]
columns = ["name", "age"]
df = spark.createDataFrame(data, columns)

print("从列表创建的DataFrame:")
df.show()

# 使用Row对象创建DataFrame
from pyspark.sql import Row
Person = Row("name", "age", "city")
people_data = [
    Person("张三", 25, "北京"),
    Person("李四", 30, "上海"),
    Person("王五", 35, "广州")
]
people_df = spark.createDataFrame(people_data)

print("使用Row创建的DataFrame:")
people_df.show()
```

### 2.3 从RDD转换

```python
# 从RDD创建DataFrame
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

# 创建RDD
rdd = spark.sparkContext.parallelize([
    ("张三", 25, "北京"),
    ("李四", 30, "上海"),
    ("王五", 35, "广州")
])

# 定义schema
schema = StructType([
    StructField("name", StringType(), True),
    StructField("age", IntegerType(), True),
    StructField("city", StringType(), True)
])

# 应用schema创建DataFrame
df_from_rdd = spark.createDataFrame(rdd, schema)

print("从RDD创建的DataFrame:")
df_from_rdd.show()
```

## 3. DataFrame基本操作

### 3.1 选择和过滤

```python
# 选择特定列
names = df.select("name")
print("仅选择姓名列:")
names.show()

# 选择多列
name_age = df.select("name", "age")
print("选择姓名和年龄列:")
name_age.show()

# 过滤行
young_people = df.filter(df.age < 30)
print("年龄小于30的人:")
young_people.show()

# 组合选择和过滤
young_names = df.filter(df.age < 30).select("name")
print("年龄小于30的人的姓名:")
young_names.show()
```

### 3.2 列操作

```python
from pyspark.sql.functions import col, expr, lit

# 添加新列
df_with_city = df.withColumn("city", lit("未知"))
print("添加城市列:")
df_with_city.show()

# 修改列
df_age_plus_one = df.withColumn("age", df.age + 1)
print("年龄加1:")
df_age_plus_one.show()

# 重命名列
df_renamed = df.withColumnRenamed("age", "年龄")
print("重命名年龄列:")
df_renamed.show()

# 删除列
df_no_age = df.drop("age")
print("删除年龄列:")
df_no_age.show()
```

### 3.3 排序和限制

```python
# 按年龄排序
df_sorted = df.sort("age")
print("按年龄升序排序:")
df_sorted.show()

# 按年龄降序排序
df_sorted_desc = df.sort(df.age.desc())
print("按年龄降序排序:")
df_sorted_desc.show()

# 限制结果数量
df_limited = df.limit(2)
print("仅显示前2行:")
df_limited.show()
```

## 4. 聚合和分组

```python
# 使用销售数据
sales_df = spark.read.option("header", "true") \
                    .option("inferSchema", "true") \
                    .csv("/home/jovyan/data/sample/sales_data.csv")

# 按类别分组并计算总销售额
from pyspark.sql.functions import sum as sum_func

category_sales = sales_df.groupBy("category") \
                        .agg(sum_func(sales_df.price * sales_df.quantity).alias("total_sales"))

print("按类别统计销售额:")
category_sales.show()

# 计算多个聚合
from pyspark.sql.functions import avg, count, max as max_func, min as min_func

category_stats = sales_df.groupBy("category").agg(
    count("*").alias("count"),
    sum_func("price").alias("total_price"),
    avg("price").alias("avg_price"),
    max_func("price").alias("max_price"),
    min_func("price").alias("min_price")
)

print("按类别的详细统计:")
category_stats.show()
```

## 5. 连接操作

```python
# 创建客户数据
customers_data = [
    (1, "张三", "北京"),
    (2, "李四", "上海"),
    (3, "王五", "广州"),
    (4, "赵六", "深圳")
]
customers_df = spark.createDataFrame(customers_data, ["id", "name", "city"])

# 创建订单数据
orders_data = [
    (101, 1, 100.0),
    (102, 2, 150.0),
    (103, 3, 200.0),
    (104, 1, 120.0),
    (105, 4, 80.0),
    (106, 5, 90.0)  # 注意：客户ID 5不存在
]
orders_df = spark.createDataFrame(orders_data, ["order_id", "customer_id", "amount"])

# 内连接
inner_join = customers_df.join(orders_df, customers_df.id == orders_df.customer_id)
print("内连接结果:")
inner_join.show()

# 左外连接
left_join = customers_df.join(orders_df, customers_df.id == orders_df.customer_id, "left")
print("左外连接结果:")
left_join.show()

# 右外连接
right_join = customers_df.join(orders_df, customers_df.id == orders_df.customer_id, "right")
print("右外连接结果:")
right_join.show()

# 全外连接
full_join = customers_df.join(orders_df, customers_df.id == orders_df.customer_id, "full")
print("全外连接结果:")
full_join.show()
```

## 6. 使用SQL查询

Spark SQL允许您使用SQL语句查询DataFrame：

```python
# 注册临时视图
sales_df.createOrReplaceTempView("sales")
customers_df.createOrReplaceTempView("customers")
orders_df.createOrReplaceTempView("orders")

# 执行SQL查询
result = spark.sql("""
    SELECT category, SUM(price * quantity) as total_sales
    FROM sales
    GROUP BY category
    ORDER BY total_sales DESC
""")

print("SQL查询结果:")
result.show()

# 连接查询
join_result = spark.sql("""
    SELECT c.name, c.city, o.order_id, o.amount
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    ORDER BY o.amount DESC
""")

print("SQL连接查询结果:")
join_result.show()
```

## 7. 保存DataFrame

```python
# 保存为CSV
sales_df.write.mode("overwrite").option("header", "true").csv("/home/jovyan/data/output/sales_csv")

# 保存为Parquet（Spark的默认格式，更高效）
sales_df.write.mode("overwrite").parquet("/home/jovyan/data/output/sales_parquet")

# 保存为JSON
sales_df.write.mode("overwrite").json("/home/jovyan/data/output/sales_json")
```

## 8. DataFrame性能优化

```python
# 缓存DataFrame
sales_df.cache()

# 或者使用特定的存储级别
from pyspark.storagelevel import StorageLevel
sales_df.persist(StorageLevel.MEMORY_AND_DISK)

# 查看执行计划
sales_df.groupBy("category").count().explain()

# 释放缓存
sales_df.unpersist()
```

## 9. 实际案例：销售数据分析

```python
# 加载销售数据
sales_df = spark.read.option("header", "true") \
                    .option("inferSchema", "true") \
                    .csv("/home/jovyan/data/sample/sales_data.csv")

# 1. 计算每个地区的总销售额
from pyspark.sql.functions import sum as sum_func, round

region_sales = sales_df.groupBy("region") \
                      .agg(round(sum_func(sales_df.price * sales_df.quantity), 2).alias("total_sales")) \
                      .orderBy("total_sales", ascending=False)

print("各地区销售额:")
region_sales.show()

# 2. 找出每个类别中价格最高的产品
from pyspark.sql.functions import max as max_func
from pyspark.sql.window import Window
import pyspark.sql.functions as F

window_spec = Window.partitionBy("category")
max_price_products = sales_df.withColumn("max_price", max_func("price").over(window_spec)) \
                           .filter(sales_df.price == F.col("max_price")) \
                           .select("category", "product_id", "price") \
                           .orderBy("price", ascending=False)

print("各类别最贵产品:")
max_price_products.show()

# 3. 计算每个客户的购买总额
customer_spending = sales_df.groupBy("customer_id") \
                          .agg(round(sum_func(sales_df.price * sales_df.quantity), 2).alias("total_spending")) \
                          .orderBy("total_spending", ascending=False)

print("客户消费排行:")
customer_spending.show()
```

## 10. 练习

### 练习1：用户行为分析

使用用户行为数据，完成以下任务：
1. 统计每种行为（view、add_to_cart、purchase）的次数
2. 找出浏览次数最多的商品
3. 计算每个用户的购买转化率（购买次数/浏览次数）

### 练习2：销售数据高级分析

使用销售数据，完成以下任务：
1. 按月份统计销售趋势
2. 计算每个类别的销售占比
3. 找出购买频率最高的客户

## 11. 总结

在本文档中，我们学习了：

1. DataFrame的基本概念和优势
2. 如何创建DataFrame（从文件、Python对象、RDD）
3. DataFrame的基本操作（选择、过滤、列操作）
4. 聚合和分组操作
5. 连接操作
6. 使用SQL查询DataFrame
7. 保存DataFrame到不同格式
8. DataFrame性能优化技巧
9. 如何应用DataFrame解决实际问题

DataFrame API是Spark中最常用的数据处理接口，它结合了SQL的易用性和Spark的分布式计算能力，是大数据分析的强大工具。

## 下一步

接下来，我们将学习Dataset API，它结合了DataFrame的优势和RDD的类型安全特性。请继续学习 `dataset-api.md` 文档。