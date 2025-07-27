# 大数据学习平台

基于 Docker 的 Apache Spark 学习环境，提供完整的容器化开发体验。

## 🚀 快速开始

### 环境要求
- Docker Desktop
- 8GB+ 内存推荐

### 一键启动
```powershell
# 快速启动开发环境 (推荐新手)
.\quick_container_start.ps1

# 启动并测试环境
.\quick_container_start.ps1 -Test
```

### 🎯 启动脚本选择

| 用户类型 | 推荐脚本 | 特点 |
|---------|----------|------|
| **新手** | `quick_container_start.ps1` ⭐ | 简单、自动测试 |
| **进阶** | `start_dev_environment.ps1` | 完整功能、可选组件 |
| **专家** | `start_environment.ps1` | 仅集群、本地开发 |

### 访问地址
- **Jupyter Lab**: http://localhost:8888 (token: `spark-learning`)
- **Spark Master UI**: http://localhost:8080
- **Spark Application UI**: http://localhost:4040

## 💡 为什么选择容器化开发？

✅ **零配置烦恼** - 无需处理 Java 版本冲突、环境变量配置  
✅ **开箱即用** - 预装所有必要的 Python 包和 Spark 组件  
✅ **国内优化** - 配置国内镜像源，安装速度快  
✅ **跨平台一致** - Windows、macOS、Linux 完全相同的体验  

## 📚 学习内容

### 基础教程
- **Spark 基础** - RDD、DataFrame、Dataset API
- **Spark SQL** - 查询、优化、性能调优
- **流处理** - DStream、Structured Streaming

### 实战项目
- **推荐系统** - 协同过滤算法实现
- **日志分析** - 大规模日志处理
- **实时仪表板** - 流数据可视化

## 🛠️ 开发方式

### 方式一：Jupyter Lab (推荐)
```
1. 访问 http://localhost:8888
2. 输入 token: spark-learning
3. 打开 container-spark-demo.ipynb 开始学习
```

### 方式二：容器内开发
```bash
# 进入开发容器
docker exec -it spark-dev bash

# 运行 Python 脚本
python3 your_script.py

# 使用 spark-submit
spark-submit your_app.py
```

## 🔧 环境管理

```powershell
# 启动环境
.\quick_container_start.ps1

# 停止环境
docker-compose down

# 查看状态
docker-compose ps

# 测试环境
docker exec -it spark-dev python3 test_container_environment.py
```

## 📖 详细指南

- [容器开发指南](CONTAINER_DEV_GUIDE.md) - 完整的使用说明
- [学习路径](notebooks/learning_path.md) - 结构化学习计划
- [示例 Notebook](notebooks/container-spark-demo.ipynb) - 快速上手示例

## 🎯 学习目标

- 掌握 Spark 分布式计算原理
- 熟练使用 PySpark API 进行数据处理
- 学会 Spark SQL 查询优化技巧
- 了解流处理和实时计算
- 具备实际项目开发能力

现在就开始你的 Spark 学习之旅吧！🚀