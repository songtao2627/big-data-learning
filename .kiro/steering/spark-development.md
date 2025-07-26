---
inclusion: fileMatch
fileMatchPattern: "*.py|*.ipynb|*spark*"
---

# Spark 开发指导

## Spark 应用开发最佳实践

### 1. SparkSession 初始化
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("YourAppName") \
    .master("spark://spark-master:7077") \
    .config("spark.executor.memory", "1g") \
    .config("spark.driver.memory", "1g") \
    .getOrCreate()
```

### 2. 数据读取优化
- 优先使用 Parquet 格式
- 设置合适的分区策略
- 使用 schema 推断避免多次扫描

```python
# 推荐方式
df = spark.read.parquet("path/to/data.parquet")

# 避免
df = spark.read.csv("path/to/data.csv", inferSchema=True)  # 会扫描两次
```

### 3. DataFrame 操作优化
- 尽早过滤数据 (filter/where)
- 使用 select 减少列数
- 合理使用 cache/persist

```python
# 好的实践
df_filtered = df.filter(df.age > 18) \
                .select("name", "age", "city") \
                .cache()

# 避免
df_all = df.cache()  # 缓存不必要的数据
df_filtered = df_all.filter(df_all.age > 18)
```

### 4. 常用配置参数
```python
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
spark.conf.set("spark.sql.execution.arrow.pyspark.enabled", "true")
```

### 5. 调试和监控
- 使用 Spark UI (http://localhost:4040)
- 检查执行计划: `df.explain()`
- 监控分区分布: `df.rdd.getNumPartitions()`

### 6. 错误处理
```python
try:
    result = spark.sql("SELECT * FROM table")
    result.show()
except Exception as e:
    print(f"Spark job failed: {e}")
    spark.sparkContext.cancelAllJobs()
```

### 7. 资源清理
```python
# 在 notebook 结束时
spark.stop()
```

## 常见问题解决

### 内存不足
- 增加 executor memory
- 减少分区大小
- 使用 repartition() 重新分区

### 数据倾斜
- 使用 salting 技术
- 调整 join 策略
- 使用广播 join

### 性能慢
- 检查分区数量
- 优化 join 顺序
- 使用列式存储格式