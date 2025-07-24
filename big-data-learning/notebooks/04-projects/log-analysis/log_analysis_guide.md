# 日志分析项目指南

## 项目概述

本项目演示如何使用Apache Spark进行大规模日志分析，包括日志解析、统计分析、错误检测、用户行为分析和异常检测等功能。

## 项目结构

```
log-analysis/
├── log_analysis.ipynb          # 主要的Jupyter笔记本
├── log_parser.py              # 日志解析器模块
├── log_analysis_guide.md      # 本指南文档
└── sample_logs/               # 示例日志文件
```

## 功能特性

### 1. 日志解析
- 支持多种日志格式（标准格式、Apache格式、Nginx格式）
- 使用正则表达式提取关键信息
- 自动识别用户ID、页面URL、API调用等

### 2. 统计分析
- 日志级别分布分析
- 时间模式分析（按小时、按天）
- 用户活动统计
- 页面访问统计

### 3. 错误分析
- 错误日志分类和统计
- 错误模式识别
- 错误趋势分析

### 4. 性能监控
- 系统性能警告检测
- 慢查询识别
- 资源使用监控

### 5. 异常检测
- 高频错误检测
- 可疑用户活动识别
- 系统异常模式识别

## 使用方法

### 快速开始

1. **启动Jupyter环境**
   ```bash
   cd big-data-learning
   docker-compose up -d
   ```

2. **打开日志分析笔记本**
   - 访问 http://localhost:8888
   - 打开 `notebooks/04-projects/log-analysis/log_analysis.ipynb`

3. **运行分析**
   - 按顺序执行笔记本中的代码单元
   - 查看分析结果和可视化图表

### 使用自定义日志文件

1. **准备日志文件**
   - 将日志文件放置在 `data/` 目录下
   - 确保日志格式符合支持的格式之一

2. **修改文件路径**
   ```python
   log_file_path = "/home/jovyan/data/your_log_file.txt"
   ```

3. **选择日志格式**
   ```python
   log_df = parser.load_and_parse_logs(log_file_path, log_format='standard')
   ```

### 使用日志解析器模块

```python
from log_parser import LogAnalyzer

# 创建分析器
analyzer = LogAnalyzer(spark)

# 运行完整分析
results = analyzer.run_complete_analysis("/path/to/logfile.txt")

# 导出结果
analyzer.export_results(results, "/path/to/output")
```

## 支持的日志格式

### 1. 标准格式
```
[2023-01-01 00:00:01] INFO  Server started successfully
[2023-01-01 00:05:23] ERROR Database connection failed
```

**格式说明**：
- `[时间戳]` - YYYY-MM-DD HH:MM:SS格式
- `级别` - INFO, WARN, ERROR等
- `消息` - 日志消息内容

### 2. Apache访问日志格式
```
192.168.1.1 - - [01/Jan/2023:00:00:01 +0000] "GET /index.html HTTP/1.1" 200 1234
```

**格式说明**：
- IP地址
- 时间戳
- HTTP方法和URL
- 状态码
- 响应大小

### 3. Nginx访问日志格式
```
192.168.1.1 - - [01/Jan/2023:00:00:01 +0000] "GET /index.html HTTP/1.1" 200 1234 "http://example.com" "Mozilla/5.0"
```

## 分析功能详解

### 日志级别分析

分析不同级别日志的分布情况：

```python
level_counts = log_df.groupBy("level").count().orderBy(desc("count"))
level_counts.show()
```

**输出示例**：
```
+-----+-----+
|level|count|
+-----+-----+
| INFO|   18|
|ERROR|    4|
| WARN|    6|
+-----+-----+
```

### 时间模式分析

分析日志在时间维度上的分布：

```python
# 按小时分析
hourly_counts = log_df_with_time.groupBy("hour").count().orderBy("hour")

# 按星期分析
daily_counts = log_df_with_time.groupBy("day_of_week").count()
```

### 错误分析

深入分析错误日志：

```python
# 错误类型分类
error_patterns = error_logs.withColumn(
    "error_type",
    when(col("message").contains("Database"), "Database Error")
    .when(col("message").contains("404"), "404 Not Found")
    .otherwise("Other Error")
)
```

### 用户行为分析

分析用户活动模式：

```python
# 用户登录统计
user_logins = log_df.filter(col("user_id").isNotNull())
                   .groupBy("user_id").count()

# 页面访问统计
page_access = log_df.filter(col("page_url").isNotNull())
                   .groupBy("page_url").count()
```

## 可视化功能

项目包含多种数据可视化功能：

### 1. 日志级别分布图
- 饼图显示各级别占比
- 柱状图显示具体数量

### 2. 时间分布图
- 折线图显示每小时日志数量
- 热力图显示时间模式

### 3. 错误类型分布图
- 柱状图显示不同错误类型的数量

### 4. 用户活动图
- 用户登录频次分布
- 页面访问热度图

## 输出结果

分析完成后，结果将保存到以下位置：

```
/home/jovyan/output/log_analysis/
├── level_counts/              # 日志级别统计
├── error_logs/               # 错误日志详情
├── error_types/              # 错误类型统计
├── user_activity/            # 用户活动统计
├── page_access/              # 页面访问统计
└── time_hourly/              # 时间分布统计
```

## 性能优化建议

### 1. 数据分区
对于大型日志文件，建议使用分区：

```python
# 按日期分区读取
log_df = spark.read.text("logs/year=2023/month=01/day=*/")
```

### 2. 缓存策略
对于重复使用的数据，启用缓存：

```python
log_df.cache()
```

### 3. 资源配置
根据数据量调整Spark配置：

```python
spark = SparkSession.builder \
    .appName("Log Analysis") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
    .getOrCreate()
```

## 扩展功能

### 1. 实时日志分析
集成Kafka和Spark Streaming实现实时分析：

```python
from pyspark.streaming import StreamingContext

# 创建流处理上下文
ssc = StreamingContext(spark.sparkContext, 10)

# 从Kafka读取日志流
kafka_stream = KafkaUtils.createStream(ssc, ...)
```

### 2. 机器学习异常检测
使用MLlib进行异常检测：

```python
from pyspark.ml.clustering import KMeans
from pyspark.ml.feature import VectorAssembler

# 特征工程
assembler = VectorAssembler(inputCols=["hour", "level_encoded"], outputCol="features")
feature_df = assembler.transform(log_df)

# K-means聚类检测异常
kmeans = KMeans(k=3, seed=1)
model = kmeans.fit(feature_df)
```

### 3. 告警系统
集成告警功能：

```python
def send_alert(error_count, threshold=10):
    if error_count > threshold:
        # 发送邮件或短信告警
        send_email("admin@example.com", f"错误数量超过阈值: {error_count}")
```

## 故障排除

### 常见问题

1. **内存不足错误**
   - 增加Spark executor内存
   - 使用数据分区
   - 启用自适应查询执行

2. **解析失败**
   - 检查日志格式是否正确
   - 验证正则表达式模式
   - 查看原始日志样本

3. **性能问题**
   - 优化查询逻辑
   - 使用列式存储格式（Parquet）
   - 调整分区数量

### 调试技巧

1. **查看执行计划**
   ```python
   log_df.explain(True)
   ```

2. **监控作业进度**
   - 访问Spark UI: http://localhost:4040
   - 查看作业执行情况和资源使用

3. **日志调试**
   ```python
   spark.sparkContext.setLogLevel("DEBUG")
   ```

## 最佳实践

1. **数据质量检查**
   - 验证日志格式一致性
   - 处理缺失值和异常值
   - 数据清洗和标准化

2. **性能监控**
   - 监控内存使用情况
   - 跟踪查询执行时间
   - 优化数据访问模式

3. **安全考虑**
   - 敏感信息脱敏
   - 访问权限控制
   - 数据加密存储

4. **可维护性**
   - 模块化代码设计
   - 完善的文档和注释
   - 单元测试覆盖

## 参考资源

- [Apache Spark官方文档](https://spark.apache.org/docs/latest/)
- [PySpark SQL指南](https://spark.apache.org/docs/latest/sql-programming-guide.html)
- [正则表达式教程](https://regexr.com/)
- [日志分析最佳实践](https://www.elastic.co/guide/en/elasticsearch/guide/current/logging.html)

## 联系支持

如有问题或建议，请通过以下方式联系：

- 项目Issues: [GitHub Issues](https://github.com/your-repo/issues)
- 邮件支持: support@example.com
- 技术文档: [项目Wiki](https://github.com/your-repo/wiki)