# 大数据学习平台

专为中文用户设计的大数据技术教学平台，提供基于Docker的Apache Spark和Flink学习环境。

## 目录结构

```
├── custom-jupyter/           # 自定义Jupyter镜像
├── data/                     # 数据集
├── notebooks/                # 学习笔记和示例
├── scripts/                  # 脚本文件
├── docker-compose.yml        # Docker编排文件
├── setup_local_environment.ps1  # 本地环境设置脚本
└── start.bat                 # 启动脚本
```

## 快速开始

### 使用Docker（推荐）

1. 安装Docker和Docker Compose
2. 克隆项目
3. 运行 `docker-compose up -d`
4. 访问 http://localhost:8888

### 本地环境

1. 安装Python 3.8+
2. 运行 `setup_local_environment.ps1` 配置环境
3. 运行 `start_local_environment.ps1` 启动环境

## 开发环境配置

为了方便在 VS Code 中运行项目中的各种脚本（Python、Jupyter Notebook、PowerShell），我们提供了详细的插件配置指南：

- [VS Code 插件配置指南](docs/vscode_plugins.md) - 推荐的 VS Code 插件列表和配置建议，帮助您更高效地开发和测试项目中的各种脚本文件

## 常见问题解答

在使用本地PySpark连接Docker中的Spark集群时，您可能会遇到各种问题。我们整理了一份详细的Q&A文档，帮助您快速解决常见问题：

- [PySpark连接Docker集群问题解答](SPARK_CLUSTER_QA.md) - 包含环境配置、网络连接、资源分配等常见问题的详细解决方案

建议在遇到连接问题时首先查阅此文档，通常可以快速找到解决方案。

## 国内镜像源支持

为了提升国内用户的下载速度，项目已集成国内镜像源支持：

- Docker环境默认使用清华大学PyPI镜像源
- 本地环境可通过脚本参数选择不同镜像源：
  ```powershell
  # 使用阿里云镜像源
  .\setup_local_environment.ps1 -Mirror aliyun
  
  # 使用豆瓣镜像源
  .\setup_local_environment.ps1 -Mirror douban
  ```

更多详细信息请查看 [镜像源使用说明](docs/mirror_usage.md)。

## 学习路径

1. Spark基础 (RDD, DataFrame, Dataset)
2. Spark SQL
3. Spark Streaming
4. 实践项目 (日志分析, 推荐系统, 实时仪表盘)

## 技术栈

- Apache Spark 3.4
- Jupyter Notebook
- Docker & Docker Compose
- Python 3.11