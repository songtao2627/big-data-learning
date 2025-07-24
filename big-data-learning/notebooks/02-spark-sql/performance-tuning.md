# Spark SQL性能调优

本文档介绍Spark SQL的性能调优技术，帮助您优化查询性能和资源利用率。

## 1. 理解Spark SQL执行过程

### 1.1 Catalyst优化器

Spark SQL使用Catalyst优化器将SQL查询转换为高效的执行计划。了解这个过程有助于编写更高效的查询。

执行过程包括以下阶段：
1. **解析**：将SQL文本解析为未解析的逻辑计划
2. **分析**：将未解析的逻辑计划转换为解析后的逻辑计划
3. **优化**：应用基于规则和成本的优化
4. **物理计划**：生成物理执行计划
5. **代码生成**：生成高效的Java字节码

### 1.2 查看执行计划

```scala
// Scala
val df = spark.sql("SELECT * FROM sales WHERE price > 100")
df.explain(true)  // 显示详细执行计划
```

```python
# Python
df = spark.sql("SELECT * FROM sales WHERE price > 100")
df.explain(True)  # 显示详细执行计划
```

执行计划包含以下信息：
- 解析后的逻辑计划
- 优化后的逻辑计划
- 物理计划
- 执行策略

## 2. 数据倾斜处理

数据倾斜是指数据分布不均匀，导致某些分区的数据量远大于其他分区，这会导致性能瓶颈。

### 2.1 识别数据倾斜

```scala
// 查看分区大小分布
df.groupBy(spark_partition_id()).count().show()
```

### 2.2 解决数据倾斜的方法

#### 2.2.1 调整并行度

```scala
// 设置默认并行度
spark.conf.set("spark.sql.shuffle.partitions", 200)

// 在查询中指定并行度
df.repartition(200).createOrReplaceTempView("better_partitioned_table")
```

#### 2.2.2 加盐技术

对于`JOIN`操作中的数据倾斜：

```sql
-- 原始查询
SELECT a.key, b.value
FROM table_a a
JOIN table_b b ON a.key = b.key

-- 加盐查询（对热点键进行扩展）
WITH a_salted AS (
    SELECT key, value, pmod(rand()*10, 10) AS salt
    FROM table_a
    WHERE key = 'hot_key'
),
b_exploded AS (
    SELECT key, value, id AS salt
    FROM table_b
    LATERAL VIEW explode(array(0,1,2,3,4,5,6,7,8,9)) t AS id
    WHERE key = 'hot_key'
),
a_normal AS (
    SELECT key, value, 0 AS salt
    FROM table_a
    WHERE key != 'hot_key'
),
b_normal AS (
    SELECT key, value, 0 AS salt
    FROM table_b
    WHERE key != 'hot_key'
)
SELECT 
    COALESCE(a_salted.key, a_normal.key) AS key,
    COALESCE(b_exploded.value, b_normal.value) AS value
FROM 
    (SELECT * FROM a_salted UNION ALL SELECT * FROM a_normal) a
JOIN 
    (SELECT * FROM b_exploded UNION ALL SELECT * FROM b_normal) b
ON a.key = b.key AND a.salt = b.salt
```

#### 2.2.3 广播连接

对于小表和大表的连接，使用广播连接可以避免shuffle：

```sql
-- 使用广播连接提示
SELECT /*+ BROADCAST(small_table) */ *
FROM large_table
JOIN small_table ON large_table.key = small_table.key
```

```scala
// 在DataFrame API中使用广播连接
import org.apache.spark.sql.functions.broadcast
val result = largeDF.join(broadcast(smallDF), "key")
```

## 3. 查询优化技术

### 3.1 谓词下推

谓词下推是将过滤条件尽早应用于数据源的优化技术。Catalyst优化器通常会自动执行此操作。

```sql
-- 优化前
SELECT a.id, a.name
FROM (SELECT * FROM users) a
WHERE a.age > 30

-- 优化后（由Catalyst自动执行）
SELECT id, name
FROM users
WHERE age > 30
```

### 3.2 列剪裁

列剪裁是只读取查询所需的列的优化技术。Catalyst优化器通常会自动执行此操作。

```sql
-- 优化前
SELECT name, age
FROM (SELECT * FROM users)

-- 优化后（由Catalyst自动执行）
SELECT name, age
FROM users
```

### 3.3 分区裁剪

对于分区表，只读取包含查询所需数据的分区。

```sql
-- 对于按日期分区的表，只读取特定日期范围的分区
SELECT *
FROM sales
WHERE date >= '2023-01-01' AND date <= '2023-01-31'
```

### 3.4 使用适当的连接策略

Spark支持多种连接策略：
- **广播哈希连接**：将小表广播到所有节点
- **排序合并连接**：对两个表进行排序，然后合并
- **哈希连接**：使用哈希表进行连接

```sql
-- 强制使用广播连接
SELECT /*+ BROADCAST(users) */ *
FROM orders
JOIN users ON orders.user_id = users.id

-- 强制使用排序合并连接
SELECT /*+ MERGE(orders, users) */ *
FROM orders
JOIN users ON orders.user_id = users.id

-- 强制使用哈希连接
SELECT /*+ SHUFFLE_HASH(orders, users) */ *
FROM orders
JOIN users ON orders.user_id = users.id
```

## 4. 内存管理

### 4.1 缓存和持久化

缓存经常使用的数据可以提高查询性能。

```scala
// 缓存DataFrame
df.cache()

// 或使用特定的存储级别
import org.apache.spark.storage.StorageLevel
df.persist(StorageLevel.MEMORY_AND_DISK_SER)

// 缓存表
spark.sql("CACHE TABLE sales")

// 取消缓存
df.unpersist()
spark.sql("UNCACHE TABLE sales")
```

常用的存储级别：
- `MEMORY_ONLY`：仅内存存储，如果内存不足则重新计算
- `MEMORY_AND_DISK`：优先内存存储，内存不足时溢写到磁盘
- `MEMORY_ONLY_SER`：序列化后存储在内存中，节省空间但增加CPU开销
- `MEMORY_AND_DISK_SER`：序列化后存储，内存不足时溢写到磁盘

### 4.2 内存配置

```scala
// 设置执行内存
spark.conf.set("spark.executor.memory", "4g")

// 设置存储内存与执行内存的比例
spark.conf.set("spark.memory.fraction", "0.6")  // 默认0.6，表示60%的内存用于执行和存储
spark.conf.set("spark.memory.storageFraction", "0.5")  // 默认0.5，表示存储内存中的50%不会被执行内存抢占
```

## 5. 数据格式和存储优化

### 5.1 选择合适的文件格式

不同文件格式的性能比较：
- **Parquet**：列式存储，高效压缩，支持谓词下推和列剪裁，推荐用于分析查询
- **ORC**：列式存储，与Parquet类似，在Hive生态系统中更常用
- **Avro**：行式存储，适合写入密集型工作负载
- **JSON/CSV**：人类可读，但查询性能较差

```scala
// 保存为Parquet格式
df.write.parquet("path/to/data")

// 读取Parquet文件
val df = spark.read.parquet("path/to/data")
```

### 5.2 压缩

```scala
// 设置压缩编解码器
spark.conf.set("spark.sql.parquet.compression.codec", "snappy")  // 可选：snappy, gzip, lzo, none
```

压缩算法比较：
- **Snappy**：中等压缩率，非常快的压缩和解压速度，推荐用于大多数场景
- **Gzip**：高压缩率，中等压缩和解压速度
- **LZO**：低压缩率，非常快的解压速度
- **None**：无压缩，最快的读写速度，但占用最多空间

### 5.3 分区和分桶

#### 5.3.1 分区

分区将数据按照指定的列分组存储在不同的目录中，有助于提高查询性能。

```sql
-- 创建分区表
CREATE TABLE sales_partitioned (
    product_id STRING,
    price DOUBLE,
    quantity INT,
    customer_id STRING
)
PARTITIONED BY (date STRING, region STRING)

-- 插入数据时指定分区
INSERT INTO sales_partitioned
PARTITION (date='2023-01-01', region='North')
SELECT product_id, price, quantity, customer_id
FROM sales
WHERE date='2023-01-01' AND region='North'
```

#### 5.3.2 分桶

分桶将数据按照指定的列哈希到固定数量的桶中，有助于提高连接和聚合性能。

```sql
-- 创建分桶表
CREATE TABLE sales_bucketed (
    date STRING,
    product_id STRING,
    price DOUBLE,
    quantity INT,
    customer_id STRING,
    region STRING
)
CLUSTERED BY (customer_id) INTO 10 BUCKETS
```

## 6. 配置调优

### 6.1 重要的Spark SQL配置参数

```scala
// 设置shuffle分区数
spark.conf.set("spark.sql.shuffle.partitions", 200)  // 默认200

// 自动广播连接阈值（小于此大小的表将被广播）
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "10m")  // 默认10MB

// 启用自适应查询执行
spark.conf.set("spark.sql.adaptive.enabled", "true")  // 默认true in Spark 3.x

// 启用动态分区裁剪
spark.conf.set("spark.sql.optimizer.dynamicPartitionPruning.enabled", "true")  // 默认true

// 启用代码生成
spark.conf.set("spark.sql.codegen.wholeStage", "true")  // 默认true

// 设置代码生成阈值
spark.conf.set("spark.sql.codegen.fallback", "true")  // 默认true
spark.conf.set("spark.sql.codegen.maxFields", "100")  // 默认100
```

### 6.2 资源配置

```scala
// 设置执行器数量
spark.conf.set("spark.executor.instances", "10")

// 设置每个执行器的核心数
spark.conf.set("spark.executor.cores", "4")

// 设置执行器内存
spark.conf.set("spark.executor.memory", "4g")

// 设置驱动器内存
spark.conf.set("spark.driver.memory", "2g")
```

## 7. 监控和调试

### 7.1 使用Spark UI

Spark UI提供了丰富的信息，帮助您监控和调试Spark应用程序：
- **Jobs**：查看作业执行情况
- **Stages**：查看每个作业的阶段
- **Tasks**：查看每个阶段的任务
- **Storage**：查看缓存的RDD和DataFrame
- **SQL**：查看SQL查询的执行计划和指标

### 7.2 使用日志

```scala
// 设置日志级别
spark.sparkContext.setLogLevel("INFO")  // 可选：ALL, DEBUG, ERROR, FATAL, INFO, OFF, TRACE, WARN
```

### 7.3 使用Spark事件日志

```scala
// 启用事件日志
spark.conf.set("spark.eventLog.enabled", "true")
spark.conf.set("spark.eventLog.dir", "hdfs://namenode:8021/spark-logs")
```

## 8. 实际案例：性能调优实践

### 8.1 优化复杂查询

原始查询：

```sql
SELECT 
    c.name,
    c.city,
    SUM(s.price * s.quantity) AS total_spent
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE s.date >= '2023-01-01'
GROUP BY c.name, c.city
ORDER BY total_spent DESC
```

优化步骤：

1. **分区裁剪**：确保`sales`表按`date`分区
2. **广播小表**：如果`customers`表较小，使用广播连接
3. **调整并行度**：根据数据量设置适当的shuffle分区数
4. **缓存中间结果**：如果查询多次使用

优化后的查询：

```sql
-- 假设sales表已按date分区
-- 使用广播连接提示
SELECT /*+ BROADCAST(c) */
    c.name,
    c.city,
    SUM(s.price * s.quantity) AS total_spent
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE s.date >= '2023-01-01'
GROUP BY c.name, c.city
ORDER BY total_spent DESC
```

### 8.2 优化数据倾斜

假设在`customer_id`列上存在数据倾斜：

```sql
-- 识别热点键
SELECT customer_id, COUNT(*) AS count
FROM sales
GROUP BY customer_id
ORDER BY count DESC
LIMIT 10

-- 对热点键使用加盐技术
WITH sales_normal AS (
    SELECT *
    FROM sales
    WHERE customer_id != 'hot_customer_id'
),
sales_skewed AS (
    SELECT 
        date, product_id, category, price, quantity,
        CONCAT(customer_id, '-', CAST(FLOOR(RAND() * 10) AS INT)) AS customer_id,
        region
    FROM sales
    WHERE customer_id = 'hot_customer_id'
),
customers_normal AS (
    SELECT *
    FROM customers
    WHERE customer_id != 'hot_customer_id'
),
customers_skewed AS (
    SELECT 
        CONCAT(customer_id, '-', id) AS customer_id,
        name, city
    FROM customers
    LATERAL VIEW explode(array(0,1,2,3,4,5,6,7,8,9)) t AS id
    WHERE customer_id = 'hot_customer_id'
)

SELECT 
    c.name,
    c.city,
    SUM(s.price * s.quantity) AS total_spent
FROM 
    (SELECT * FROM sales_normal UNION ALL SELECT * FROM sales_skewed) s
JOIN 
    (SELECT * FROM customers_normal UNION ALL SELECT * FROM customers_skewed) c
ON s.customer_id = c.customer_id
GROUP BY c.name, c.city
ORDER BY total_spent DESC
```

## 9. 总结

本文档介绍了Spark SQL的性能调优技术，包括：

1. 理解Spark SQL执行过程
2. 数据倾斜处理
3. 查询优化技术
4. 内存管理
5. 数据格式和存储优化
6. 配置调优
7. 监控和调试
8. 实际案例

通过应用这些技术，您可以显著提高Spark SQL查询的性能和资源利用率。

## 下一步

接下来，我们将学习Spark Streaming，它提供了处理实时数据流的能力。请继续学习 `../03-spark-streaming/dstream-basics.md` 文档。