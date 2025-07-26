---
inclusion: manual
---

# 故障排除指南

## 脚本工具引用
#[[file:scripts/troubleshoot.ps1]]
#[[file:scripts/health_check.ps1]]
#[[file:scripts/verify_environment.ps1]]

## 常见问题诊断

### 1. 容器启动问题

#### 症状
- `docker-compose up -d` 失败
- 容器状态显示 "Exited" 或 "Unhealthy"

#### 诊断步骤
```bash
# 检查容器状态
docker-compose ps

# 查看详细日志
docker-compose logs [service-name]

# 检查端口占用
netstat -an | findstr :8080
```

#### 常见解决方案
1. **端口冲突**: 修改 docker-compose.yml 中的端口映射
2. **内存不足**: 增加 Docker Desktop 内存限制
3. **磁盘空间**: 清理 Docker 镜像和容器
4. **权限问题**: 确保数据卷路径有正确权限

### 2. Spark 集群连接问题

#### 症状
- Jupyter 无法连接到 Spark Master
- Worker 节点未注册到 Master

#### 诊断步骤
```python
# 在 Jupyter 中测试连接
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("ConnectionTest") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

print(f"Spark Version: {spark.version}")
print(f"Master URL: {spark.sparkContext.master}")
```

#### 解决方案
1. **网络问题**: 检查 Docker 网络配置
2. **服务发现**: 确认服务名称解析正确
3. **防火墙**: 检查端口 7077 是否开放

### 3. 性能问题

#### 症状
- Spark 作业运行缓慢
- 内存溢出错误
- 任务失败重试

#### 诊断工具
- Spark UI: http://localhost:4040
- Spark Master UI: http://localhost:8080
- 系统监控: `docker stats`

#### 优化策略
1. **调整分区数**: `df.repartition(num_partitions)`
2. **增加内存**: 修改 executor/driver memory 配置
3. **优化数据格式**: 使用 Parquet 替代 CSV
4. **缓存策略**: 合理使用 `cache()` 和 `persist()`

### 4. 数据处理错误

#### 常见错误类型
- **Schema 不匹配**: 数据类型转换失败
- **空值处理**: NullPointerException
- **编码问题**: 字符编码错误

#### 调试技巧
```python
# 检查数据质量
df.printSchema()
df.describe().show()
df.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) for c in df.columns]).show()

# 采样调试
sample_df = df.sample(0.01).collect()
```

## 监控和日志

### 重要日志位置
- Spark Master: `/opt/bitnami/spark/logs/`
- Spark Worker: `/opt/bitnami/spark/logs/`
- Jupyter: Docker logs

### 监控指标
- CPU 使用率
- 内存使用率
- 磁盘 I/O
- 网络流量
- Spark 作业执行时间

### 告警设置
```python
# 简单的性能监控
def monitor_job_performance(spark_context):
    status = spark_context.statusTracker()
    print(f"Active Jobs: {len(status.getActiveJobIds())}")
    print(f"Active Stages: {len(status.getActiveStageIds())}")
    
    for executor in status.getExecutorInfos():
        print(f"Executor {executor.executorId}: {executor.totalCores} cores")
```

## 恢复策略

### 数据恢复
1. **检查备份**: 确认数据备份完整性
2. **重新处理**: 从源数据重新生成
3. **增量恢复**: 只处理缺失的数据分区

### 服务恢复
```bash
# 完全重启
docker-compose down
docker-compose up -d

# 单个服务重启
docker-compose restart spark-master

# 清理并重启
docker-compose down -v
docker-compose up -d
```

### 配置恢复
- 使用版本控制恢复配置文件
- 检查环境变量设置
- 验证网络和存储配置

## 预防措施

### 定期维护
- 清理临时文件和日志
- 更新 Docker 镜像
- 备份重要数据和配置

### 监控设置
- 设置资源使用告警
- 监控作业执行状态
- 跟踪错误日志

### 文档更新
- 记录问题和解决方案
- 更新故障排除流程
- 分享最佳实践