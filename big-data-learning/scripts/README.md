# 大数据学习平台脚本说明

本目录包含了管理大数据学习平台环境的各种PowerShell脚本。这些脚本可以帮助您轻松启动、管理和维护学习环境。

## 🚀 快速开始

对于初学者，推荐使用以下命令快速启动环境：

```powershell
# 一键启动基础环境
.\quick_start.ps1

# 或者使用环境管理工具
.\manage_environment.ps1 start
```

## 📋 脚本列表

### 核心管理脚本

| 脚本名称 | 功能描述 | 推荐使用场景 |
|---------|---------|-------------|
| `manage_environment.ps1` | 统一的环境管理入口 | 日常环境管理 |
| `quick_start.ps1` | 一键启动脚本 | 初学者快速开始 |
| `start_environment.ps1` | 详细的环境启动脚本 | 需要自定义启动选项 |
| `health_check.ps1` | 环境健康检查 | 检查环境状态 |
| `verify_environment.ps1` | 完整环境验证 | 深度环境测试 |
| `troubleshoot.ps1` | 故障排除工具 | 解决环境问题 |

### 辅助脚本

| 脚本名称 | 功能描述 | 使用场景 |
|---------|---------|---------|
| `initialize_environment.ps1` | 环境初始化 | 首次安装后运行 |
| `stop_environment.ps1` | 停止环境 | 关闭所有服务 |
| `check_spark_cluster.ps1` | Spark集群检查 | 验证Spark配置 |

## 🛠️ 详细使用说明

### 1. 环境管理工具 (manage_environment.ps1)

这是推荐的主要管理工具，提供统一的环境管理接口。

```powershell
# 基本用法
.\manage_environment.ps1 <action> [options]

# 可用操作
start        # 启动环境
stop         # 停止环境
restart      # 重启环境
status       # 检查状态
verify       # 验证环境
troubleshoot # 故障排除
clean        # 清理环境
help         # 显示帮助

# 示例
.\manage_environment.ps1 start           # 启动基础环境
.\manage_environment.ps1 start -Full    # 启动完整环境
.\manage_environment.ps1 status -Detailed # 详细状态检查
.\manage_environment.ps1 troubleshoot -Auto # 自动故障排除
```

### 2. 一键启动 (quick_start.ps1)

最简单的启动方式，适合初学者。

```powershell
# 基础环境启动
.\quick_start.ps1

# 完整环境启动 (包含Kafka, Elasticsearch等)
.\quick_start.ps1 -Full

# 重置并启动
.\quick_start.ps1 -Reset

# 显示帮助
.\quick_start.ps1 -Help
```

### 3. 健康检查 (health_check.ps1)

检查环境是否正常运行。

```powershell
# 基本健康检查
.\health_check.ps1

# 详细检查
.\health_check.ps1 -Detailed

# 包含流处理组件检查
.\health_check.ps1 -Streaming

# 包含分析组件检查
.\health_check.ps1 -Analytics

# 快速检查
.\health_check.ps1 -Quick

# JSON格式输出
.\health_check.ps1 -Json
```

### 4. 环境验证 (verify_environment.ps1)

进行完整的环境功能验证。

```powershell
# 基本验证
.\verify_environment.ps1

# 详细验证
.\verify_environment.ps1 -Detailed

# 跳过Spark测试
.\verify_environment.ps1 -SkipSpark

# 跳过Jupyter测试
.\verify_environment.ps1 -SkipJupyter
```

### 5. 故障排除 (troubleshoot.ps1)

诊断和解决环境问题。

```powershell
# 交互式故障排除菜单
.\troubleshoot.ps1

# 自动诊断
.\troubleshoot.ps1 -Auto

# 重置环境
.\troubleshoot.ps1 -Reset

# 完全清理
.\troubleshoot.ps1 -CleanAll

# 查看特定问题的解决方案
.\troubleshoot.ps1 -Issue port    # 端口问题
.\troubleshoot.ps1 -Issue docker  # Docker问题
.\troubleshoot.ps1 -Issue memory  # 内存问题
```

## 🔧 常见使用场景

### 场景1: 首次使用

```powershell
# 1. 初始化环境
.\initialize_environment.ps1

# 2. 启动环境
.\quick_start.ps1

# 3. 验证环境
.\verify_environment.ps1
```

### 场景2: 日常使用

```powershell
# 启动环境
.\manage_environment.ps1 start

# 检查状态
.\manage_environment.ps1 status

# 停止环境
.\manage_environment.ps1 stop
```

### 场景3: 遇到问题

```powershell
# 1. 检查环境状态
.\health_check.ps1 -Detailed

# 2. 自动诊断
.\troubleshoot.ps1 -Auto

# 3. 如果问题严重，重置环境
.\manage_environment.ps1 restart -Reset
```

### 场景4: 完整环境 (包含Kafka, Elasticsearch)

```powershell
# 启动完整环境
.\manage_environment.ps1 start -Full

# 检查所有组件
.\health_check.ps1 -Streaming -Analytics -Detailed
```

## 📊 环境组件

### 基础组件 (默认启动)
- **Jupyter Notebook**: http://localhost:8888
- **Spark Master UI**: http://localhost:8080
- **Spark Worker 1 UI**: http://localhost:8081
- **Spark Worker 2 UI**: http://localhost:8082

### 流处理组件 (使用 -Streaming 或 -Full)
- **Kafka**: localhost:9092
- **Zookeeper**: localhost:2181

### 分析组件 (使用 -Analytics 或 -Full)
- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601

## ⚠️ 注意事项

### 系统要求
- Windows 10/11
- Docker Desktop
- PowerShell 5.1 或更高版本
- 至少 4GB 可用内存
- 至少 10GB 可用磁盘空间

### 端口要求
确保以下端口未被占用：
- 8888 (Jupyter Notebook)
- 8080 (Spark Master)
- 8081, 8082 (Spark Workers)
- 9092 (Kafka, 可选)
- 9200 (Elasticsearch, 可选)
- 5601 (Kibana, 可选)

### 权限要求
- 需要管理员权限来执行某些Docker操作
- 确保PowerShell执行策略允许运行脚本

## 🐛 故障排除

### 常见问题

1. **Docker未启动**
   ```powershell
   .\troubleshoot.ps1 -Issue docker
   ```

2. **端口被占用**
   ```powershell
   .\troubleshoot.ps1 -Issue port
   ```

3. **内存不足**
   ```powershell
   .\troubleshoot.ps1 -Issue memory
   ```

4. **网络连接问题**
   ```powershell
   .\troubleshoot.ps1 -Issue network
   ```

### 获取帮助

1. **查看脚本帮助**
   ```powershell
   .\manage_environment.ps1 help
   .\quick_start.ps1 -Help
   ```

2. **自动诊断**
   ```powershell
   .\troubleshoot.ps1 -Auto
   ```

3. **查看日志**
   ```powershell
   docker-compose logs -f
   ```

## 📚 学习资源

启动环境后，可以访问以下学习资源：

1. **欢迎笔记本**: `notebooks/00-welcome.ipynb`
2. **学习路径**: `notebooks/learning_path.md`
3. **调试指南**: `notebooks/debugging-guide.md`
4. **示例数据**: `data/sample/`

## 🤝 贡献

如果您发现脚本中的问题或有改进建议，欢迎提出Issue或Pull Request。

## 📄 许可证

本项目采用MIT许可证，详见LICENSE文件。