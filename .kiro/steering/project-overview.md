---
inclusion: always
---

# 大数据学习平台项目总览

## 项目结构引用
#[[file:README.md]]

## 快速开始

### 环境启动
```bash
# 启动基础环境
docker-compose up -d

# 启动包含流处理的完整环境
docker-compose --profile streaming up -d

# 检查服务状态
docker-compose ps
```

### 访问地址
- **Jupyter Notebook**: http://localhost:8888
- **Spark Master UI**: http://localhost:8080
- **Spark Worker 1**: http://localhost:8081
- **Spark Worker 2**: http://localhost:8082

## 核心组件

### 1. Spark 集群
- **Master**: 1个主节点，负责资源调度
- **Workers**: 2个工作节点，每个2核4GB内存
- **配置**: 支持 Python/Scala，启用自适应查询执行

### 2. Jupyter 环境
- **镜像**: jupyter/pyspark-notebook:latest
- **预装**: PySpark, pandas, matplotlib, seaborn
- **配置**: 自动连接到 Spark 集群

### 3. 数据存储
- **本地挂载**: ./data 目录映射到容器
- **支持格式**: CSV, JSON, Parquet
- **示例数据**: 包含多种类型的样本数据集

## 学习路径

### 阶段1: Spark 基础 (notebooks/01-spark-basics/)
- RDD 基础操作
- DataFrame API
- Dataset API
- 基础数据处理

### 阶段2: Spark SQL (notebooks/02-spark-sql/)
- SQL 基础查询
- 高级查询技巧
- 性能调优
- 案例研究

### 阶段3: 流处理 (notebooks/03-spark-streaming/)
- DStream 基础
- Structured Streaming
- Kafka 集成
- 实时数据处理

### 阶段4: 实战项目 (notebooks/04-projects/)
- 推荐系统
- 日志分析
- 实时仪表板
- 综合项目

## 开发工作流

### 1. 代码开发
- 在 Jupyter 中编写和测试代码
- 使用 Git 进行版本控制
- 遵循项目编码规范

### 2. 数据处理
- 将数据文件放入 data/ 目录
- 使用标准的 ETL 流程
- 进行数据质量检查

### 3. 性能优化
- 监控 Spark UI
- 分析执行计划
- 调整配置参数

### 4. 部署和运维
- 使用 Docker Compose 管理服务
- 监控系统资源使用
- 定期备份重要数据

## 故障排除

### 常用诊断命令
```bash
# 检查容器状态
docker-compose ps

# 查看服务日志
docker-compose logs spark-master

# 重启服务
docker-compose restart [service-name]

# 完全重建
docker-compose down && docker-compose up -d
```

### 性能监控
- Spark UI: 监控作业执行
- Docker Stats: 监控资源使用
- 系统日志: 检查错误信息

## 扩展功能

### 可选组件
- **Kafka**: 流数据处理
- **Elasticsearch**: 数据搜索和分析
- **Kibana**: 数据可视化

### 自定义配置
- 修改 docker-compose.yml 调整资源配置
- 编辑 spark-defaults.conf 优化 Spark 参数
- 使用环境变量自定义行为

## 最佳实践

### 代码质量
- 使用类型提示
- 编写文档字符串
- 进行单元测试
- 代码审查

### 数据管理
- 使用合适的数据格式
- 实施数据版本控制
- 建立数据质量检查
- 定期清理临时数据

### 性能优化
- 合理设置分区
- 使用缓存策略
- 优化 Join 操作
- 监控资源使用