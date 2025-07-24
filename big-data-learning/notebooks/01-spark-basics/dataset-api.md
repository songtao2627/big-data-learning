# Spark Dataset API

本文档介绍Spark的Dataset API，它结合了RDD的类型安全和DataFrame的优化执行引擎。

## 什么是Dataset？

Dataset是Spark 1.6中引入的一个新接口，它提供了RDD的类型安全和DataFrame的优化执行引擎的优点。Dataset API在Scala和Java中可用，而在Python中，由于Python是动态类型语言，所以主要使用DataFrame API。

Dataset的主要特点：
- **类型安全**：编译时类型检查，避免运行时错误
- **优化执行**：使用Catalyst优化器和Tungsten执行引擎
- **面向对象编程**：支持强类型的JVM对象操作
- **序列化效率**：比Java序列化更高效的编码器

## 1. 创建SparkSession

首先，我们需要创建一个SparkSession：

```scala
// Scala代码
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("Dataset API")
  .getOrCreate()

// 导入隐式转换
import spark.implicits._
```

```java
// Java代码
import org.apache.spark.sql.SparkSession;

SparkSession spark = SparkSession.builder()
  .appName("Dataset API")
  .getOrCreate();
```

## 2. 创建Dataset

有多种方法可以创建Dataset：

### 2.1 从Scala集合创建

```scala
// 定义一个case class
case class Person(name: String, age: Int)

// 从Seq创建Dataset
val personSeq = Seq(Person("张三", 25), Person("李四", 30), Person("王五", 35))
val personDS = personSeq.toDS()

// 显示Dataset内容
personDS.show()
```

### 2.2 从DataFrame转换

```scala
// 从DataFrame转换为Dataset
val personDF = spark.read.json("people.json")
val personDS = personDF.as[Person]
```

### 2.3 从RDD转换

```scala
// 从RDD转换为Dataset
val personRDD = spark.sparkContext.parallelize(personSeq)
val personDS = spark.createDataset(personRDD)
```

## 3. Dataset操作

Dataset API提供了两种类型的操作：

1. **类型化操作**：使用强类型的lambda函数（如map、filter、groupByKey）
2. **非类型化操作**：使用DataFrame API（如select、groupBy）

### 3.1 类型化操作

```scala
// 过滤操作
val youngPersons = personDS.filter(p => p.age < 30)

// map操作
val names = personDS.map(p => p.name)

// flatMap操作
val characters = personDS.flatMap(p => p.name.toSeq)

// 聚合操作
val averageAge = personDS.map(_.age).reduce(_ + _) / personDS.count()
```

### 3.2 非类型化操作

```scala
// 选择特定列
val nameDF = personDS.select("name")

// 过滤行
val youngDF = personDS.filter($"age" < 30)

// 分组聚合
val ageStats = personDS.groupBy("age").count()
```

## 4. 编码器

编码器是Dataset API的核心组件，它负责将JVM对象转换为Spark内部的二进制格式。Spark提供了许多内置编码器：

```scala
// 基本类型编码器
val intDS = Seq(1, 2, 3).toDS()
val stringDS = Seq("a", "b", "c").toDS()

// 复杂类型编码器
import org.apache.spark.sql.Encoders
val personEncoder = Encoders.product[Person]
val personDS = spark.createDataset(personSeq)(personEncoder)
```

## 5. Dataset与DataFrame和RDD的比较

### Dataset vs DataFrame

- DataFrame是Dataset[Row]的类型别名
- DataFrame使用非类型化API，Dataset使用类型化API
- DataFrame在运行时检查类型，Dataset在编译时检查类型

### Dataset vs RDD

- Dataset使用Catalyst优化器，RDD不使用
- Dataset使用高效的二进制格式，RDD使用Java序列化
- Dataset提供了结构化数据处理API，RDD提供了函数式编程API

## 6. 实际案例：销售数据分析

```scala
// 定义销售记录类
case class SalesRecord(date: String, productId: String, category: String, 
                      price: Double, quantity: Int, customerId: String, region: String)

// 读取CSV文件并转换为Dataset
val salesDS = spark.read
  .option("header", "true")
  .option("inferSchema", "true")
  .csv("/home/jovyan/data/sample/sales_data.csv")
  .as[SalesRecord]

// 计算每个类别的总销售额
val categorySales = salesDS
  .groupByKey(_.category)
  .mapGroups { (category, records) =>
    val totalSales = records.map(r => r.price * r.quantity).sum
    (category, totalSales)
  }
  .toDF("category", "total_sales")
  .orderBy($"total_sales".desc)

// 显示结果
categorySales.show()
```

## 7. Dataset最佳实践

1. **使用case class**：为数据定义清晰的结构
2. **利用类型安全**：在编译时捕获错误
3. **结合DataFrame API**：在需要时使用非类型化操作
4. **缓存中间结果**：对于多次使用的Dataset
5. **使用内置函数**：利用优化的内置函数而不是UDF

## 8. Python中的Dataset

在Python中，由于语言的动态特性，没有真正的Dataset API。PySpark主要使用DataFrame API，它在内部使用Row对象，这些对象是无类型的。

```python
# Python中使用DataFrame
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("DataFrame in Python") \
    .getOrCreate()

# 创建DataFrame
data = [("张三", 25), ("李四", 30), ("王五", 35)]
df = spark.createDataFrame(data, ["name", "age"])

# 使用DataFrame API
young_people = df.filter(df.age < 30)
young_people.show()
```

## 9. 总结

Dataset API结合了RDD的类型安全和DataFrame的优化执行引擎，是Spark中一个强大的数据处理接口。它特别适合于Scala和Java开发者，他们可以利用静态类型检查的优势。

在实际应用中，选择使用Dataset、DataFrame还是RDD取决于多种因素：
- 需要类型安全和编译时错误检查？选择Dataset
- 需要最佳性能和简洁的API？选择DataFrame
- 需要对非结构化数据进行低级操作？选择RDD

## 下一步

接下来，我们将学习Spark SQL，它提供了一种使用SQL语句查询结构化数据的方式。请继续学习 `../02-spark-sql/sql-basics.md` 文档。