# 大数据学习平台 - 学习资料索引

欢迎使用大数据学习平台！本文档提供了所有学习资料的索引，帮助您快速找到需要的内容。

## 学习路径

建议按照以下顺序学习：

1. **入门指南**
   - [欢迎使用大数据学习平台](./00-welcome.ipynb)
   - [学习路径指南](./learning_path.md)

2. **Spark基础**
   - [RDD基础](./01-spark-basics/rdd-fundamentals.md)
   - [DataFrame操作](./01-spark-basics/dataframe-operations.md)
   - [Dataset API](./01-spark-basics/dataset-api.md)

3. **Spark SQL**
   - [SQL基础](./02-spark-sql/sql-basics.md)
   - [高级查询](./02-spark-sql/advanced-queries.md)
   - [性能调优](./02-spark-sql/performance-tuning.md)

4. **Spark Streaming**
   - [DStream基础](./03-spark-streaming/dstream-basics.md)
   - [结构化流](./03-spark-streaming/structured-streaming.md)
   - [Kafka集成](./03-spark-streaming/kafka-integration.md)

5. **实践项目**
   - [日志分析项目](./04-projects/log-analysis/README.md)
   - [推荐系统项目](./04-projects/recommendation-system/README.md)
   - [实时仪表盘项目](./04-projects/real-time-dashboard/README.md)

6. **Flink学习**
   - [DataStream API](./05-flink/datastream-api.md)
   - [Table API](./05-flink/table-api.md)
   - [Spark与Flink对比](./05-flink/spark-vs-flink.md)

## 数据集

本平台提供以下示例数据集：

1. **小型数据集**
   - `data/sample/sales_data.csv`: 销售数据
   - `data/sample/user_behavior.json`: 用户行为数据
   - `data/sample/server_logs.txt`: 服务器日志数据

2. **中型数据集**
   - `data/medium/ecommerce_transactions.parquet`: 电商交易数据
   - `data/medium/social_network.json`: 社交网络数据
   - `data/medium/sensor_data.csv`: 传感器数据

3. **大型数据集**
   - `data/large/web_clickstream/`: 网站点击流数据
   - `data/large/financial_data/`: 金融交易数据

## 参考资源

- [Apache Spark官方文档](https://spark.apache.org/docs/latest/)
- [Apache Flink官方文档](https://flink.apache.org/docs/stable/)
- [PySpark API参考](https://spark.apache.org/docs/latest/api/python/index.html)

## 常见问题

如果您在学习过程中遇到问题，请参考以下资源：

1. 检查环境健康状态：运行 `scripts/health_check.ps1`
2. 查看Spark UI：访问 http://localhost:8080
3. 查看Jupyter日志：运行 `docker logs jupyter-notebook`

## 学习进度跟踪

您可以在 `learning_path.md` 文件中记录您的学习进度。