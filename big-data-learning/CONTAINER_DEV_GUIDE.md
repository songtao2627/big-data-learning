# 容器化开发环境使用指南

## 概述

为了解决 Windows 环境下 PySpark 配置复杂的问题，我们提供了一个完整的容器化开发环境。你可以在容器内进行所有的 Spark 开发工作，避免本地环境配置问题。

## 快速开始

### 1. 一键启动 (推荐)

```powershell
# 快速启动并测试环境
.\quick_container_start.ps1 -Test

# 仅启动环境
.\quick_container_start.ps1

# 清理重启
.\quick_container_start.ps1 -Clean -Test
```

### 2. 详细启动选项

```powershell
# 启动基础开发环境 (推荐)
.\scripts\start_dev_environment.ps1 -DevOnly

# 启动完整环境 (包含所有组件)
.\scripts\start_dev_environment.ps1 -All

# 强制重建环境
.\scripts\start_dev_environment.ps1 -Force
```

### 2. 访问开发环境

- **Jupyter Lab**: http://localhost:8888 (token: `spark-learning`)
- **Spark Master UI**: http://localhost:8080
- **Spark Application UI**: http://localhost:4040 (运行应用时)

### 3. 进入容器进行开发

```bash
# 进入开发容器
docker exec -it spark-dev bash

# 在容器内，你可以：
# - 运行 Python 脚本
# - 使用 spark-submit 提交任务
# - 访问所有 Spark 工具
```

## 开发工作流

### 方式一：Jupyter Lab 开发 (推荐)

1. 打开 http://localhost:8888
2. 输入 token: `spark-learning`
3. 在 `notebooks/` 目录下创建或编辑 notebook
4. 直接运行 PySpark 代码，自动连接到集群

### 方式二：容器内命令行开发

```bash
# 进入容器
docker exec -it spark-dev bash

# 创建 Python 脚本
cat > /opt/bitnami/spark/my_spark_app.py << 'EOF'
from pyspark.sql import SparkSession

# 创建 Spark 会话，连接到集群
spark = SparkSession.builder \
    .appName("MySparkApp") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

# 创建测试数据
data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
columns = ["name", "age"]
df = spark.createDataFrame(data, columns)

# 显示结果
df.show()

# 停止 Spark 会话
spark.stop()
EOF

# 运行脚本
python3 my_spark_app.py

# 或使用 spark-submit
spark-submit my_spark_app.py
```

### 方式三：本地编辑，容器执行

```bash
# 在 Windows 本地编辑文件 (如 VSCode)
# 文件保存在 notebooks/ 或 scripts/ 目录

# 在容器内执行
docker exec -it spark-dev python3 /opt/bitnami/spark/notebooks/my_script.py
```

## 环境配置

### 预装组件

容器内已预装：
- Python 3.x
- PySpark 3.4
- Jupyter Lab
- pandas, matplotlib, seaborn, plotly, numpy, scipy, scikit-learn
- requests, beautifulsoup4 (网络和数据处理)
- py4j, findspark (Spark 集成)
- 所有必要的 Java 环境
- 国内镜像源配置 (pip, apt)

### 数据访问

- 本地 `data/` 目录映射到容器 `/opt/bitnami/spark/data/`
- 本地 `notebooks/` 目录映射到容器 `/opt/bitnami/spark/notebooks/`
- 本地 `scripts/` 目录映射到容器 `/opt/bitnami/spark/scripts/`

### Spark 配置

容器自动配置连接到 Spark 集群：
- Master URL: `spark://spark-master:7077`
- 自动发现 Worker 节点
- 优化的内存和 CPU 设置

## 常用命令

### 环境管理

```powershell
# 启动环境
.\scripts\start_dev_environment.ps1 -DevOnly

# 停止环境
.\scripts\stop_environment.ps1

# 查看容器状态
docker-compose ps

# 查看开发容器日志
docker-compose logs -f spark-dev
```

### 容器操作

```bash
# 进入开发容器
docker exec -it spark-dev bash

# 在容器内安装额外的 Python 包 (自动使用国内镜像源)
pip install package-name

# 手动配置镜像源 (如果需要)
bash /opt/bitnami/spark/scripts/setup_mirrors.sh

# 测试环境
python3 /opt/bitnami/spark/test_container_environment.py

# 重启开发容器
docker-compose restart spark-dev
```

### 调试和监控

```bash
# 运行环境测试
docker exec -it spark-dev python3 test_container_environment.py

# 查看 Spark 集群状态
# 访问 http://localhost:8080 查看集群状态
# 访问 http://localhost:4040 查看当前应用状态

# 检查镜像源配置
docker exec -it spark-dev cat ~/.pip/pip.conf
```

## 优势

### 解决的问题

1. **Java 版本冲突**: 容器内使用统一的 Java 环境
2. **环境变量配置**: 自动配置所有必要的环境变量
3. **依赖管理**: 预装所有必要的依赖包
4. **跨平台一致性**: 在任何支持 Docker 的系统上都能运行

### 开发体验

1. **即开即用**: 一条命令启动完整环境
2. **隔离性**: 不影响本地系统环境
3. **可重现**: 环境配置完全一致
4. **易于分享**: 团队成员使用相同环境

## 故障排除

### 常见问题

1. **容器启动失败**
   ```bash
   # 检查 Docker 状态
   docker version
   
   # 清理并重启
   .\scripts\start_dev_environment.ps1 -Force
   ```

2. **Jupyter 无法访问**
   ```bash
   # 检查端口占用
   netstat -an | findstr 8888
   
   # 重启开发容器
   docker-compose restart spark-dev
   ```

3. **Spark 连接失败**
   ```bash
   # 检查集群状态
   docker-compose ps
   
   # 查看 Master 日志
   docker-compose logs spark-master
   ```

### 性能优化

1. **增加容器资源**
   - 在 Docker Desktop 中增加内存和 CPU 分配
   - 修改 docker-compose.yml 中的资源限制

2. **数据本地化**
   - 将大数据文件放在 `data/` 目录下
   - 使用 Parquet 格式提高读取性能

这个容器化环境让你完全摆脱 Windows 环境配置的烦恼，专注于 Spark 学习和开发！