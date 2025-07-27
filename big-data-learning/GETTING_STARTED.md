# 🚀 快速上手指南

## 📋 环境要求

- **Docker Desktop** (必需)
- **8GB+ 内存** (推荐)
- **Windows 10/11, macOS, 或 Linux**

## ⚡ 一分钟快速开始

```powershell
# 1. 克隆项目
git clone <repository-url>
cd big-data-learning

# 2. 一键启动并测试
.\quick_container_start.ps1 -Test

# 3. 开始学习
# 访问 http://localhost:8888 (token: spark-learning)
```

就这么简单！🎉

## 🎯 推荐学习路径

### 第一步：验证环境
```powershell
.\quick_container_start.ps1 -Test
```
确保所有服务正常运行，网络连通性良好。

### 第二步：打开 Jupyter Lab
1. 访问 http://localhost:8888
2. 输入 token: `spark-learning`
3. 打开 `container-spark-demo.ipynb`

### 第三步：按顺序学习
1. **Spark 基础** (`notebooks/01-spark-basics/`)
   - RDD 基础操作
   - DataFrame API
   - Dataset API

2. **Spark SQL** (`notebooks/02-spark-sql/`)
   - SQL 基础查询
   - 高级查询技巧
   - 性能调优

3. **流处理** (`notebooks/03-spark-streaming/`)
   - DStream 基础
   - Structured Streaming
   - Kafka 集成

4. **实战项目** (`notebooks/04-projects/`)
   - 推荐系统
   - 日志分析
   - 实时仪表板

## 🛠️ 常用操作

### 环境管理
```powershell
# 启动环境
.\quick_container_start.ps1

# 清理重启
.\quick_container_start.ps1 -Clean

# 停止环境
docker-compose down

# 查看状态
docker-compose ps
```

### 开发操作
```powershell
# 进入开发容器
docker exec -it spark-dev bash

# 运行 Python 脚本
docker exec -it spark-dev python3 your_script.py

# 使用 spark-submit
docker exec -it spark-dev spark-submit your_app.py

# 查看日志
docker-compose logs -f spark-dev
```

### 测试和诊断
```powershell
# 环境测试
docker exec -it spark-dev python3 test_container_environment.py

# 网络测试
docker exec -it spark-dev python3 test_network_connectivity.py

# 查看 Spark UI
# http://localhost:8080 (集群状态)
# http://localhost:4040 (应用状态)
```

## 📚 重要文档

| 文档 | 用途 |
|------|------|
| [SCRIPTS_OVERVIEW.md](SCRIPTS_OVERVIEW.md) | 脚本总览和使用指南 ⭐ |
| [CONTAINER_DEV_GUIDE.md](CONTAINER_DEV_GUIDE.md) | 容器开发详细指南 |
| [SCRIPTS_COMPARISON.md](SCRIPTS_COMPARISON.md) | 启动脚本对比说明 |
| [NETWORK_TROUBLESHOOTING.md](NETWORK_TROUBLESHOOTING.md) | 网络问题排除 |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | 项目结构说明 |
| [notebooks/learning_path.md](notebooks/learning_path.md) | 学习路径规划 |

## 🔧 三个启动脚本的区别

| 特性 | `quick_container_start.ps1` | `start_dev_environment.ps1` | `start_environment.ps1` |
|------|---------------------------|----------------------------|------------------------|
| **目标用户** | 新手 ⭐ | 高级用户 | 专业用户 |
| **开发容器** | ✅ 包含 | ✅ 包含 | ❌ 不包含 |
| **Jupyter Lab** | ✅ 8888端口 | ✅ 8888端口 | ❌ 无 |
| **可选组件** | ❌ 不支持 | ✅ Kafka/ES/Kibana | ✅ Kafka/ES/Kibana |
| **自动测试** | ✅ -Test参数 | ❌ 无 | ❌ 无 |

### 选择建议
- **90% 的用户**: 使用 `quick_container_start.ps1` ⭐
- **需要高级功能**: 使用 `start_dev_environment.ps1`
- **本地开发专家**: 使用 `start_environment.ps1`

### 高级功能示例
```powershell
# 启动流处理组件 (Kafka)
.\scripts\start_dev_environment.ps1 -Streaming

# 启动分析组件 (Elasticsearch/Kibana)
.\scripts\start_dev_environment.ps1 -Analytics

# 启动所有组件
.\scripts\start_dev_environment.ps1 -All

# 仅启动集群 (本地开发)
.\scripts\start_environment.ps1
```

## ❓ 常见问题

### Q: 启动失败怎么办？
```powershell
# 1. 检查 Docker 是否运行
docker version

# 2. 清理重启
.\quick_container_start.ps1 -Clean -Test

# 3. 查看日志
docker-compose logs
```

### Q: 网络连接问题？
```powershell
# 运行网络诊断
docker exec -it spark-dev python3 test_network_connectivity.py

# 查看网络故障排除指南
# 阅读 NETWORK_TROUBLESHOOTING.md
```

### Q: 性能问题？
- 确保 Docker Desktop 分配足够内存 (8GB+)
- 关闭不必要的应用程序
- 检查系统资源使用情况

### Q: 想要自定义配置？
- 修改 `docker-compose.yml` 调整资源配置
- 编辑 `scripts/spark-defaults.conf` 优化 Spark 参数
- 查看 `CONTAINER_DEV_GUIDE.md` 了解详细配置

## 🎉 开始学习

现在你已经准备好开始 Spark 学习之旅了！

1. **运行**: `.\quick_container_start.ps1 -Test`
2. **访问**: http://localhost:8888
3. **学习**: 从 `container-spark-demo.ipynb` 开始
4. **实践**: 完成各个学习模块和项目

祝你学习愉快！🚀

## 💡 小贴士

- 使用 `Ctrl+C` 可以停止正在运行的脚本
- Jupyter Lab 支持多种文件格式编辑
- 可以在容器内安装额外的 Python 包
- 定期运行测试脚本确保环境正常
- 遇到问题先查看相关文档，大部分问题都有解决方案