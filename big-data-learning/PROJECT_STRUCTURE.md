# 项目结构说明

## 📁 目录结构

```
big-data-learning/
├── 📄 README.md                    # 项目说明
├── 📄 CONTAINER_DEV_GUIDE.md       # 容器开发指南
├── 📄 docker-compose.yml           # Docker 编排文件
├── 📄 quick_container_start.ps1    # 一键启动脚本
├── 📄 test_container_environment.py # 环境测试脚本
├── 
├── 📁 scripts/                     # 核心脚本文件
│   ├── start_environment.ps1       # 启动 Spark 集群
│   ├── start_dev_environment.ps1   # 启动开发环境
│   ├── stop_environment.ps1        # 停止环境
│   ├── setup_mirrors.sh            # 配置镜像源
│   ├── spark-defaults.conf         # Spark 配置
│   └── data_generator.py           # 示例数据生成
├── 
├── 📁 data/                        # 数据文件
│   ├── sample/                     # 示例数据
│   └── datasets_description.md     # 数据集说明
├── 
└── 📁 notebooks/                   # 学习材料
    ├── container-spark-demo.ipynb  # 容器开发示例
    ├── 00-welcome.ipynb            # 欢迎页面
    ├── learning_path.md            # 学习路径
    ├── index.md                    # 学习材料索引
    ├── 
    ├── 📁 01-spark-basics/         # Spark 基础
    ├── 📁 02-spark-sql/            # Spark SQL
    ├── 📁 03-spark-streaming/      # 流处理
    └── 📁 04-projects/             # 实战项目
```

## 🚀 核心文件说明

### 启动脚本
- **`quick_container_start.ps1`** - 推荐使用，一键启动 + 自动测试 ⭐
- **`scripts/start_dev_environment.ps1`** - 完整开发环境 + 可选组件
- **`scripts/start_environment.ps1`** - 仅启动 Spark 集群

### 配置文件
- **`docker-compose.yml`** - 定义所有服务容器，包含网络优化
- **`scripts/spark-defaults.conf`** - Spark 默认配置

### 测试和诊断工具
- **`test_container_environment.py`** - 快速环境测试
- **`test_network_connectivity.py`** - 详细网络连通性测试
- **`scripts/setup_mirrors.sh`** - 配置国内镜像源

### 文档指南
- **`GETTING_STARTED.md`** - 快速上手指南 ⭐
- **`CONTAINER_DEV_GUIDE.md`** - 详细开发指南
- **`SCRIPTS_COMPARISON.md`** - 启动脚本对比
- **`NETWORK_TROUBLESHOOTING.md`** - 网络故障排除

### 学习材料
- **`notebooks/container-spark-demo.ipynb`** - 容器环境使用示例
- **`notebooks/learning_path.md`** - 结构化学习计划
- **各个学习模块** - 从基础到实战的完整教程

## 💡 使用建议

1. **新手入门**: 直接运行 `.\quick_container_start.ps1 -Test`
2. **日常开发**: 使用 Jupyter Lab 进行交互式开发
3. **生产脚本**: 在容器内使用 `spark-submit` 提交任务
4. **学习路径**: 按照 `notebooks/learning_path.md` 的顺序学习

## 🔧 环境管理

```powershell
# 启动完整环境
.\quick_container_start.ps1

# 仅启动集群
.\scripts\start_environment.ps1

# 停止环境
docker-compose down

# 清理重启
.\quick_container_start.ps1 -Clean
```

这个结构设计让你能够专注于 Spark 学习，而不用担心环境配置问题！