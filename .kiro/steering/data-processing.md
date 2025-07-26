---
inclusion: fileMatch
fileMatchPattern: "*data*|*.csv|*.json|*.parquet"
---

# 数据处理规范

## 数据文件引用
#[[file:data/datasets_description.md]]

## 数据格式标准

### 支持的数据格式
- **CSV**: 结构化数据，适合小到中等规模数据集
- **JSON**: 半结构化数据，适合嵌套数据结构
- **Parquet**: 列式存储，适合大规模数据分析
- **Delta Lake**: 版本化数据湖格式（高级用法）

### 数据命名规范
```
数据文件命名格式: [domain]_[type]_[date].format
示例:
- sales_transactions_20240101.parquet
- user_behavior_streaming.json
- product_catalog_master.csv
```

### 数据目录结构
```
data/
├── raw/           # 原始数据
├── processed/     # 处理后数据
├── sample/        # 示例数据
└── output/        # 输出结果
```

## 数据质量检查

### 必要的数据验证
```python
def validate_dataframe(df, required_columns=None):
    """数据质量检查函数"""
    print(f"数据行数: {df.count()}")
    print(f"数据列数: {len(df.columns)}")
    
    # 检查空值
    null_counts = df.select([
        F.sum(F.col(c).isNull().cast("int")).alias(c) 
        for c in df.columns
    ]).collect()[0].asDict()
    
    print("空值统计:")
    for col, null_count in null_counts.items():
        if null_count > 0:
            print(f"  {col}: {null_count}")
    
    # 检查必需列
    if required_columns:
        missing_cols = set(required_columns) - set(df.columns)
        if missing_cols:
            raise ValueError(f"缺少必需列: {missing_cols}")
    
    return df
```

### 数据清洗标准流程
1. **去重**: 移除重复记录
2. **空值处理**: 填充或删除空值
3. **数据类型转换**: 确保正确的数据类型
4. **异常值检测**: 识别和处理异常值
5. **数据标准化**: 统一数据格式

## 性能优化指导

### 数据读取优化
```python
# 推荐: 指定 schema 避免推断
schema = StructType([
    StructField("id", IntegerType(), True),
    StructField("name", StringType(), True),
    StructField("timestamp", TimestampType(), True)
])

df = spark.read.schema(schema).csv("path/to/data.csv")
```

### 数据写入优化
```python
# 推荐: 使用分区写入大数据集
df.write \
  .partitionBy("year", "month") \
  .mode("overwrite") \
  .parquet("output/partitioned_data")
```

### 缓存策略
```python
# 对于重复使用的数据集
df_cached = df.filter(df.status == "active").cache()

# 使用后释放缓存
df_cached.unpersist()
```

## 数据安全规范

### 敏感数据处理
- 不在代码中硬编码敏感信息
- 使用数据脱敏技术
- 实施访问控制

### 数据备份
- 定期备份重要数据
- 使用版本控制管理数据变更
- 建立数据恢复流程

## 常用数据处理模式

### ETL 流程模板
```python
def etl_pipeline(input_path, output_path):
    # Extract
    raw_df = spark.read.json(input_path)
    
    # Transform
    cleaned_df = raw_df \
        .filter(F.col("status").isNotNull()) \
        .withColumn("processed_date", F.current_date()) \
        .dropDuplicates()
    
    # Load
    cleaned_df.write \
        .mode("overwrite") \
        .parquet(output_path)
    
    return cleaned_df.count()
```

### 数据聚合模式
```python
# 时间窗口聚合
daily_stats = df \
    .groupBy(F.date_trunc("day", "timestamp")) \
    .agg(
        F.count("*").alias("total_records"),
        F.avg("value").alias("avg_value"),
        F.max("value").alias("max_value")
    )
```

### 数据关联模式
```python
# 高效的 join 操作
result = large_df.join(
    F.broadcast(small_df),  # 广播小表
    "common_key",
    "left"
)
```