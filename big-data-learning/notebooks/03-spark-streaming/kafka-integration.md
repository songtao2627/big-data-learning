# Spark Streaming与Kafka集成

本文档介绍如何将Spark Streaming与Apache Kafka集成，处理实时消息流。

## 什么是Kafka？

Apache Kafka是一个分布式流处理平台，主要用于构建实时数据管道和流应用程序。它具有以下特点：

- **高吞吐量**：能够处理大量数据
- **可扩展性**：支持水平扩展
- **持久性**：消息持久化存储
- **容错性**：支持数据复制和故障恢复

## 1. 环境准备

### 1.1 Docker Compose配置

首先，我们需要在docker-compose.yml中添加Kafka和Zookeeper服务：

```yaml
version: '3'
services:
  # ... 现有服务 ...
  
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      - spark-network

  kafka:
    image: confluentinc/cp-kafka:latest
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    networks:
      - spark-network
```

### 1.2 Spark依赖配置

需要添加Kafka连接器依赖：

```python
# 在创建SparkSession时添加Kafka包
spark = SparkSession.builder \
    .appName("Kafka Integration") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0") \
    .getOrCreate()
```

## 2. 基本Kafka操作

### 2.1 创建Kafka主题

```bash
# 进入Kafka容器
docker exec -it kafka bash

# 创建主题
kafka-topics --create --topic sales-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# 列出主题
kafka-topics --list --bootstrap-server localhost:9092

# 查看主题详情
kafka-topics --describe --topic sales-events --bootstrap-server localhost:9092
```

### 2.2 生产者示例

```python
from kafka import KafkaProducer
import json
import time
import random

# 创建Kafka生产者
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# 发送消息
def send_sales_events():
    products = ['laptop', 'phone', 'tablet', 'watch']
    regions = ['North', 'South', 'East', 'West']
    
    for i in range(100):
        event = {
            'event_id': f'event_{i}',
            'timestamp': int(time.time()),
            'product': random.choice(products),
            'price': random.randint(100, 1000),
            'quantity': random.randint(1, 5),
            'region': random.choice(regions)
        }
        
        producer.send('sales-events', event)
        print(f"Sent: {event}")
        time.sleep(1)
    
    producer.flush()
    producer.close()

# 运行生产者
send_sales_events()
```

### 2.3 消费者示例

```python
from kafka import KafkaConsumer
import json

# 创建Kafka消费者
consumer = KafkaConsumer(
    'sales-events',
    bootstrap_servers=['localhost:9092'],
    value_deserializer=lambda m: json.loads(m.decode('utf-8')),
    group_id='sales-consumer-group',
    auto_offset_reset='earliest'
)

# 消费消息
for message in consumer:
    event = message.value
    print(f"Received: {event}")
```

## 3. Spark Streaming与Kafka集成

### 3.1 从Kafka读取流数据

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# 创建SparkSession
spark = SparkSession.builder \
    .appName("Kafka Spark Integration") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0") \
    .getOrCreate()

# 从Kafka读取流数据
kafka_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "sales-events") \
    .option("startingOffsets", "latest") \
    .load()

# 显示Kafka流的schema
kafka_stream.printSchema()
```

### 3.2 解析Kafka消息

```python
# 定义销售事件的schema
sales_schema = StructType([
    StructField("event_id", StringType(), True),
    StructField("timestamp", LongType(), True),
    StructField("product", StringType(), True),
    StructField("price", IntegerType(), True),
    StructField("quantity", IntegerType(), True),
    StructField("region", StringType(), True)
])

# 解析Kafka消息
parsed_stream = kafka_stream.select(
    col("key").cast("string"),
    col("value").cast("string"),
    col("topic"),
    col("partition"),
    col("offset"),
    col("timestamp").alias("kafka_timestamp")
).select(
    col("*"),
    from_json(col("value"), sales_schema).alias("data")
).select(
    col("key"),
    col("topic"),
    col("partition"),
    col("offset"),
    col("kafka_timestamp"),
    col("data.*")
)

# 显示解析后的数据
query = parsed_stream.writeStream \
    .outputMode("append") \
    .format("console") \
    .option("truncate", "false") \
    .start()

query.awaitTermination(30)  # 运行30秒
query.stop()
```

### 3.3 流数据处理

```python
# 添加计算列
enhanced_stream = parsed_stream.select(
    col("*"),
    (col("price") * col("quantity")).alias("total_amount"),
    from_unixtime(col("timestamp")).cast("timestamp").alias("event_time")
)

# 实时聚合
region_sales = enhanced_stream \
    .groupBy("region") \
    .agg(
        sum("total_amount").alias("total_sales"),
        count("*").alias("order_count"),
        avg("total_amount").alias("avg_order_value")
    )

# 输出聚合结果
aggregation_query = region_sales \
    .writeStream \
    .outputMode("complete") \
    .format("console") \
    .trigger(processingTime='10 seconds') \
    .start()

aggregation_query.awaitTermination(60)  # 运行60秒
aggregation_query.stop()
```

### 3.4 窗口操作

```python
# 时间窗口聚合
windowed_sales = enhanced_stream \
    .withWatermark("event_time", "10 seconds") \
    .groupBy(
        "product",
        window(col("event_time"), "1 minute", "30 seconds")
    ) \
    .agg(
        sum("total_amount").alias("window_sales"),
        count("*").alias("window_orders")
    )

# 输出窗口结果
window_query = windowed_sales \
    .writeStream \
    .outputMode("update") \
    .format("console") \
    .option("truncate", "false") \
    .trigger(processingTime='15 seconds') \
    .start()

window_query.awaitTermination(90)  # 运行90秒
window_query.stop()
```

## 4. 将结果写回Kafka

### 4.1 基本写入操作

```python
# 处理后的数据写回Kafka
def write_to_kafka(df, epoch_id):
    df.select(
        col("region").alias("key"),
        to_json(struct(
            col("region"),
            col("total_sales"),
            col("order_count"),
            col("avg_order_value")
        )).alias("value")
    ).write \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("topic", "sales-summary") \
    .save()

# 使用foreachBatch写入Kafka
kafka_write_query = region_sales \
    .writeStream \
    .foreachBatch(write_to_kafka) \
    .trigger(processingTime='20 seconds') \
    .start()

kafka_write_query.awaitTermination(60)
kafka_write_query.stop()
```

### 4.2 直接写入Kafka

```python
# 直接将流写入Kafka
kafka_output = enhanced_stream.select(
    col("event_id").alias("key"),
    to_json(struct(
        col("event_id"),
        col("product"),
        col("region"),
        col("total_amount"),
        col("event_time")
    )).alias("value")
)

kafka_sink_query = kafka_output \
    .writeStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("topic", "processed-events") \
    .option("checkpointLocation", "/tmp/kafka-checkpoint") \
    .trigger(processingTime='10 seconds') \
    .start()

kafka_sink_query.awaitTermination(60)
kafka_sink_query.stop()
```

## 5. 高级配置

### 5.1 Kafka配置参数

```python
# 高级Kafka配置
advanced_kafka_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "sales-events") \
    .option("startingOffsets", "earliest") \
    .option("maxOffsetsPerTrigger", 1000) \
    .option("kafka.session.timeout.ms", 30000) \
    .option("kafka.request.timeout.ms", 60000) \
    .option("kafka.group.id", "spark-streaming-group") \
    .option("kafka.auto.offset.reset", "latest") \
    .option("kafka.enable.auto.commit", "false") \
    .load()
```

### 5.2 多主题订阅

```python
# 订阅多个主题
multi_topic_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "sales-events,user-events,system-events") \
    .load()

# 使用主题模式订阅
pattern_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribePattern", ".*-events") \
    .load()
```

### 5.3 分区和偏移量管理

```python
# 指定特定分区和偏移量
specific_partition_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("assign", '{"sales-events":[0,1,2]}') \
    .option("startingOffsets", '{"sales-events":{"0":100,"1":200,"2":300}}') \
    .load()
```

## 6. 实际案例：实时推荐系统

### 6.1 用户行为流处理

```python
# 用户行为事件schema
user_behavior_schema = StructType([
    StructField("user_id", StringType(), True),
    StructField("item_id", StringType(), True),
    StructField("action", StringType(), True),
    StructField("timestamp", LongType(), True),
    StructField("category", StringType(), True)
])

# 从Kafka读取用户行为数据
user_behavior_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "user-behavior") \
    .load() \
    .select(
        from_json(col("value").cast("string"), user_behavior_schema).alias("data")
    ).select("data.*") \
    .withColumn("event_time", from_unixtime(col("timestamp")).cast("timestamp"))

# 计算用户兴趣
user_interests = user_behavior_stream \
    .filter(col("action") == "view") \
    .withWatermark("event_time", "5 minutes") \
    .groupBy(
        "user_id",
        "category",
        window(col("event_time"), "10 minutes", "5 minutes")
    ) \
    .count() \
    .select(
        col("user_id"),
        col("category"),
        col("window.start").alias("window_start"),
        col("window.end").alias("window_end"),
        col("count").alias("interest_score")
    )

# 输出用户兴趣
interest_query = user_interests \
    .writeStream \
    .outputMode("update") \
    .format("console") \
    .trigger(processingTime='30 seconds') \
    .start()
```

### 6.2 实时推荐生成

```python
# 热门商品统计
popular_items = user_behavior_stream \
    .filter(col("action").isin(["view", "purchase"])) \
    .withWatermark("event_time", "5 minutes") \
    .groupBy(
        "item_id",
        "category",
        window(col("event_time"), "1 hour", "30 minutes")
    ) \
    .agg(
        sum(when(col("action") == "view", 1).otherwise(0)).alias("views"),
        sum(when(col("action") == "purchase", 1).otherwise(0)).alias("purchases")
    ) \
    .withColumn("popularity_score", col("views") + col("purchases") * 5)

# 生成推荐
recommendations = popular_items \
    .filter(col("popularity_score") > 10) \
    .select(
        col("item_id"),
        col("category"),
        col("popularity_score"),
        col("window.start").alias("window_start")
    )

# 将推荐结果写入Kafka
def write_recommendations(df, epoch_id):
    df.select(
        col("category").alias("key"),
        to_json(struct(
            col("item_id"),
            col("category"),
            col("popularity_score"),
            col("window_start")
        )).alias("value")
    ).write \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("topic", "recommendations") \
    .save()

recommendation_query = recommendations \
    .writeStream \
    .foreachBatch(write_recommendations) \
    .trigger(processingTime='1 minute') \
    .start()
```

## 7. 监控和调试

### 7.1 Kafka监控

```python
# 监控Kafka流的进度
def monitor_kafka_stream(query):
    while query.isActive:
        progress = query.lastProgress
        if progress:
            print(f"Batch ID: {progress['batchId']}")
            print(f"Input Rows: {progress.get('inputRowsPerSecond', 0)}")
            print(f"Process Rows: {progress.get('processedRowsPerSecond', 0)}")
            
            # Kafka特定指标
            sources = progress.get('sources', [])
            for source in sources:
                if source.get('description', '').startswith('KafkaV2'):
                    print(f"Kafka Source: {source}")
        
        time.sleep(10)

# 在后台监控
import threading
monitor_thread = threading.Thread(target=monitor_kafka_stream, args=(kafka_stream_query,))
monitor_thread.start()
```

### 7.2 错误处理

```python
# 错误处理和重试机制
def process_with_error_handling(df, epoch_id):
    try:
        # 处理数据
        processed_df = df.filter(col("price") > 0)  # 过滤无效数据
        
        # 写入结果
        processed_df.write \
            .format("kafka") \
            .option("kafka.bootstrap.servers", "localhost:9092") \
            .option("topic", "processed-data") \
            .save()
            
    except Exception as e:
        print(f"Error in batch {epoch_id}: {str(e)}")
        # 可以选择将错误数据写入错误主题
        df.select(
            lit("error").alias("key"),
            to_json(struct(
                lit(str(e)).alias("error_message"),
                lit(epoch_id).alias("batch_id"),
                current_timestamp().alias("error_time")
            )).alias("value")
        ).write \
        .format("kafka") \
        .option("kafka.bootstrap.servers", "localhost:9092") \
        .option("topic", "error-events") \
        .save()

error_handling_query = parsed_stream \
    .writeStream \
    .foreachBatch(process_with_error_handling) \
    .start()
```

## 8. 性能优化

### 8.1 批处理大小优化

```python
# 优化批处理大小
optimized_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "sales-events") \
    .option("maxOffsetsPerTrigger", 10000) \
    .option("minPartitions", 4) \
    .load()
```

### 8.2 并行度调整

```python
# 调整Kafka分区和Spark分区的映射
repartitioned_stream = parsed_stream.repartition(8)

# 或者基于键重新分区
key_partitioned_stream = parsed_stream.repartition(col("region"))
```

## 9. 总结

本文档介绍了Spark Streaming与Kafka集成的完整流程，包括：

1. 环境准备和配置
2. 基本Kafka操作
3. 从Kafka读取流数据
4. 流数据处理和转换
5. 将结果写回Kafka
6. 高级配置选项
7. 实际案例：实时推荐系统
8. 监控和调试技术
9. 性能优化策略

Kafka与Spark Streaming的集成为构建实时数据处理管道提供了强大的基础，能够处理大规模的实时数据流并提供低延迟的处理能力。

## 下一步

接下来，我们将学习如何使用这些流处理技术来构建实际的项目。请继续学习 `../04-projects/` 目录下的实践项目。