---
inclusion: fileMatch
fileMatchPattern: "*docker*|*.yml|*.yaml"
---

# Docker 环境管理指导

## 容器服务说明

### 核心服务
- **spark-master**: Spark 主节点 (端口: 8080, 7077, 6066)
- **spark-worker-1**: Spark 工作节点 1 (端口: 8081)
- **spark-worker-2**: Spark 工作节点 2 (端口: 8082)
- **jupyter-notebook**: Jupyter 开发环境 (端口: 8888)

### 可选服务 (profiles)
- **streaming**: Kafka + Zookeeper (端口: 9092, 2181)
- **analytics**: Elasticsearch + Kibana (端口: 9200, 5601)

## 常用命令

### 基本操作
```bash
# 启动所有服务
docker-compose up -d

# 启动包含流处理组件
docker-compose --profile streaming up -d

# 启动包含分析组件
docker-compose --profile analytics up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs [service-name]

# 停止服务
docker-compose down
```

### 健康检查
```bash
# 检查 Spark 集群状态
curl http://localhost:8080

# 检查 Jupyter 状态
curl http://localhost:8888

# 进入容器调试
docker exec -it spark-master bash
```

### 数据卷管理
```bash
# 查看数据卷
docker volume ls

# 清理未使用的数据卷
docker volume prune
```

## 故障排除

### 常见问题

1. **容器启动失败**
   - 检查端口占用: `netstat -an | findstr :8080`
   - 查看容器日志: `docker logs container-name`
   - 检查磁盘空间: `docker system df`

2. **健康检查失败**
   - 确认服务进程运行: `docker exec container-name ps aux`
   - 检查网络连接: `docker network ls`

3. **性能问题**
   - 调整内存限制
   - 检查 CPU 使用率
   - 优化数据卷挂载

### 配置调优

#### Spark Master 配置
```yaml
environment:
  - SPARK_DAEMON_MEMORY=1g
  - SPARK_MASTER_OPTS=-Dspark.deploy.defaultCores=4
```

#### Spark Worker 配置
```yaml
environment:
  - SPARK_WORKER_MEMORY=2G
  - SPARK_WORKER_CORES=2
```

#### Jupyter 配置
```yaml
environment:
  - JUPYTER_ENABLE_LAB=yes
  - SPARK_DRIVER_MEMORY=1g
```

## 网络配置

### 自定义网络
```yaml
networks:
  spark-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 服务发现
- 容器间通过服务名通信
- Spark Master URL: `spark://spark-master:7077`
- Jupyter 连接: `spark-master:7077`

## 数据持久化

### 重要数据卷
- `spark-logs`: Spark 日志
- `spark-work`: Spark 工作目录
- `./notebooks`: Jupyter notebooks
- `./data`: 数据文件

### 备份策略
```bash
# 备份 notebooks
docker cp jupyter-notebook:/home/jovyan/work ./backup/

# 备份数据
tar -czf data-backup.tar.gz ./data/
```