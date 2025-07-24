# 大数据学习平台

这是一个基于Docker的大数据学习平台，专注于Apache Spark和Flink技术栈的学习。该平台提供了完整的学习环境，包括交互式Jupyter Notebook、Spark集群和示例数据集。

## 环境要求

- Windows操作系统
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- 至少4GB可用内存
- 至少10GB可用磁盘空间

## 快速开始

### 启动环境

1. 确保Docker Desktop已启动并运行
2. 打开PowerShell，进入项目根目录
3. 运行启动脚本：

```powershell
.\scripts\start_environment.ps1
```

启动脚本将：
- 启动所有必要的Docker容器
- 获取Jupyter Notebook的访问令牌
- 自动在浏览器中打开Jupyter Notebook
- 运行健康检查确认环境状态

### 停止环境

运行停止脚本：

```powershell
.\scripts\stop_environment.ps1
```

### 检查环境状态

随时可以运行健康检查脚本来验证环境状态：

```powershell
.\scripts\health_check.ps1
```

## 环境组件

- **Jupyter Notebook**: http://localhost:8888
  - 交互式Python/Scala开发环境
  - 预装PySpark、Pandas、Matplotlib等库

- **Spark Master**: http://localhost:8080
  - Spark集群管理界面
  - 查看作业执行状态和资源使用情况

- **Spark Worker 1**: http://localhost:8081
  - Spark工作节点1状态界面

- **Spark Worker 2**: http://localhost:8082
  - Spark工作节点2状态界面

## 目录结构

```
big-data-learning/
├── data/                  # 数据集目录
├── notebooks/             # Jupyter笔记本目录
├── scripts/               # 脚本和工具
│   ├── health_check.ps1   # 环境健康检查脚本
│   ├── start_environment.ps1  # 环境启动脚本
│   └── stop_environment.ps1   # 环境停止脚本
├── docker-compose.yml     # Docker环境配置
└── README.md              # 项目说明文档
```

## 学习路径

1. **Spark基础**
   - RDD编程模型
   - DataFrame和Dataset API
   - Spark SQL

2. **Spark高级功能**
   - Spark Streaming
   - 性能监控和调优

3. **实践项目**
   - 日志分析
   - 推荐系统

4. **Flink学习**
   - Flink基础概念
   - DataStream API
   - DataSet API

## 故障排除

如果遇到问题，请尝试以下步骤：

1. 运行健康检查脚本查看环境状态
2. 检查Docker容器日志：`docker-compose logs -f`
3. 重启环境：先运行停止脚本，然后运行启动脚本
4. 确保Docker Desktop有足够的资源分配（内存、CPU）

## 注意事项

- 首次启动时，Docker会下载所需镜像，可能需要一些时间
- 数据保存在`./data`目录，容器重启不会丢失
- Jupyter笔记本保存在`./notebooks`目录