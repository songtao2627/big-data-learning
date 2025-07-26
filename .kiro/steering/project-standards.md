---
inclusion: always
---

# 大数据学习平台 - 项目标准和规范

## 项目概述
这是一个基于 Docker 的大数据学习平台，包含 Apache Spark 集群和 Jupyter Notebook 环境，用于学习和实践大数据处理技术。

## 技术栈
- **容器化**: Docker & Docker Compose
- **大数据处理**: Apache Spark 3.4.3
- **开发环境**: Jupyter Notebook with PySpark
- **编程语言**: Python, Scala (可选)
- **数据格式**: CSV, JSON, Parquet
- **流处理**: Kafka (可选组件)

## 代码规范

### Python 代码规范
- 使用 PEP 8 代码风格
- 函数和类必须有文档字符串
- 使用类型提示 (Type Hints)
- 变量命名使用 snake_case
- 常量使用 UPPER_CASE

### Spark 代码规范
- DataFrame 操作优于 RDD 操作
- 使用 Spark SQL 进行复杂查询
- 合理设置分区数量
- 避免使用 collect() 操作大数据集
- 使用缓存 (cache/persist) 优化重复使用的数据

### 文件组织规范
```
big-data-learning/
├── notebooks/          # Jupyter notebooks
│   ├── 01-spark-basics/ # Spark 基础教程
│   ├── 02-spark-sql/    # Spark SQL 教程
│   ├── 03-spark-streaming/ # 流处理教程
│   └── 04-projects/     # 实战项目
├── data/               # 数据文件
├── scripts/            # 脚本文件
└── docker-compose.yml  # 容器编排
```

## 性能优化指导
- 合理设置 Spark 配置参数
- 使用适当的数据格式 (Parquet > JSON > CSV)
- 避免数据倾斜
- 使用广播变量处理小表关联
- 合理使用分区和分桶

## 安全规范
- 不在代码中硬编码敏感信息
- 使用环境变量管理配置
- 定期更新依赖包版本
- 限制容器权限

## 文档规范
- 每个 notebook 必须有清晰的标题和说明
- 代码块前后要有解释性文字
- 提供运行结果示例
- 包含学习目标和知识点总结