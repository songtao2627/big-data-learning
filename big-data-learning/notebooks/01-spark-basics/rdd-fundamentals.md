# Spark RDD基础

本文档介绍Spark的核心抽象：弹性分布式数据集（Resilient Distributed Dataset，简称RDD）。

## 什么是RDD？

RDD是Spark的基础数据结构，具有以下特点：
- **弹性**：可以从失败中恢复
- **分布式**：数据分布在集群的多个节点上
- **数据集**：是一个不可变的分布式对象集合

RDD支持两种类型的操作：
- **转换（Transformations）**：从现有RDD创建新RDD的操作（如map、filter）
- **动作（Actions）**：返回值或将结果写入存储系统的操作（如count、collect）

## 1. 创建SparkSession

首先，我们需要创建一个SparkSession，这是与Spark交互的入口点。

```python
from pyspark.sql import SparkSession

# 创建SparkSession
spark = SparkSession.builder \
    .appName("RDD基础") \
    .getOrCreate()

# 获取SparkContext
sc = spark.sparkContext

# 显示Spark版本
print(f"Spark版本: {spark.version}")
```

## 2. 创建RDD

有多种方法可以创建RDD：
1. 从集合（列表、集合等）创建
2. 从外部数据源（文件、数据库等）创建
3. 从现有RDD转换得到

### 2.1 从集合创建RDD

```python
# 从列表创建RDD
data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
rdd1 = sc.parallelize(data)

# 查看RDD内容
print("RDD1内容:")
print(rdd1.collect())

# 创建带分区的RDD
rdd2 = sc.parallelize(data, 4)  # 4个分区
print(f"RDD2分区数: {rdd2.getNumPartitions()}")

# 创建键值对RDD
pairs = [("a", 1), ("b", 2), ("c", 3)]
pairRDD = sc.parallelize(pairs)
print("键值对RDD内容:")
print(pairRDD.collect())
```

### 2.2 从文件创建RDD

```python
# 从文本文件创建RDD
logFile = "/home/jovyan/data/sample/server_logs.txt"
logRDD = sc.textFile(logFile)

# 查看前几行
print("日志文件前5行:")
for line in logRDD.take(5):
    print(line)
```

## 3. RDD转换操作

转换操作会从现有RDD创建新的RDD。这些操作是**惰性**的，只有在执行动作操作时才会计算。

### 3.1 基本转换操作

```python
# map: 对每个元素应用函数
squared = rdd1.map(lambda x: x * x)
print("平方后的RDD:")
print(squared.collect())

# filter: 过滤元素
even = rdd1.filter(lambda x: x % 2 == 0)
print("偶数RDD:")
print(even.collect())

# flatMap: 将每个元素展平为多个元素
words = sc.parallelize(["Hello Spark", "Learning RDD", "Big Data"])
flatWords = words.flatMap(lambda line: line.split(" "))
print("单词RDD:")
print(flatWords.collect())
```

### 3.2 键值对RDD转换操作

```python
# 创建一个更大的键值对RDD
kvData = [("apple", 3), ("banana", 2), ("orange", 5), ("apple", 1), ("banana", 4)]
kvRDD = sc.parallelize(kvData)

# reduceByKey: 按键聚合值
sumByKey = kvRDD.reduceByKey(lambda a, b: a + b)
print("按键求和:")
print(sumByKey.collect())

# groupByKey: 按键分组
groupedByKey = kvRDD.groupByKey().mapValues(list)
print("按键分组:")
print(groupedByKey.collect())
```

## 4. RDD动作操作

动作操作会触发计算并返回结果或将结果写入外部存储系统。

```python
# 使用之前创建的数字RDD
numbersRDD = sc.parallelize(range(1, 101))

# count: 计数
count = numbersRDD.count()
print(f"元素数量: {count}")

# first: 获取第一个元素
first = numbersRDD.first()
print(f"第一个元素: {first}")

# take: 获取前n个元素
taken = numbersRDD.take(5)
print(f"前5个元素: {taken}")

# reduce: 使用函数聚合元素
sum_result = numbersRDD.reduce(lambda a, b: a + b)
print(f"总和: {sum_result}")
```

## 5. 实际案例：单词计数

让我们使用RDD实现经典的单词计数示例。

```python
# 创建一个包含文本的RDD
text = [
    "Apache Spark是一个开源的分布式计算系统",
    "Spark提供了一个接口用于编程整个集群",
    "Spark的RDD是分布式数据集合",
    "RDD是Spark的核心抽象",
    "Spark支持Python、Java、Scala和R语言"
]
textRDD = sc.parallelize(text)

# 实现单词计数
# 1. 将每行文本拆分为单词
words = textRDD.flatMap(lambda line: line.split(" "))

# 2. 将每个单词映射为(word, 1)的键值对
word_pairs = words.map(lambda word: (word, 1))

# 3. 按单词聚合计数
word_counts = word_pairs.reduceByKey(lambda a, b: a + b)

# 4. 按计数降序排序
sorted_counts = word_counts.sortBy(lambda x: x[1], ascending=False)

# 显示结果
print("单词计数结果:")
for word, count in sorted_counts.collect():
    print(f"{word}: {count}")
```

## 6. 练习

### 练习1：分析日志文件

使用日志文件，完成以下任务：
1. 统计不同日志级别（INFO、ERROR、WARN）的消息数量
2. 找出包含特定关键字（如"error"、"failed"）的日志行
3. 按小时统计日志数量

### 练习2：销售数据分析

使用示例销售数据，完成以下任务：
1. 计算每个产品类别的总销售额
2. 找出销售量最高的产品
3. 按地区统计销售情况

## 7. 总结

在本文档中，我们学习了：

1. RDD的基本概念和特点
2. 如何创建RDD（从集合、文件等）
3. RDD的转换操作（map、filter、flatMap等）
4. RDD的动作操作（collect、count、reduce等）
5. 键值对RDD的特殊操作（reduceByKey、groupByKey等）
6. 如何应用RDD解决实际问题

RDD是Spark的基础，虽然在较新的Spark版本中DataFrame和Dataset API更为常用，但理解RDD对于深入掌握Spark非常重要。

## 下一步

接下来，我们将学习Spark的DataFrame API，它提供了更高级的抽象和更好的性能优化。请继续学习 `dataframe-operations.md` 文档。