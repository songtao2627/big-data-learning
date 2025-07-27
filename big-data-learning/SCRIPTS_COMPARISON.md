# 启动脚本对比说明

## 📊 脚本功能对比

| 特性 | `quick_container_start.ps1` | `start_dev_environment.ps1` | `start_environment.ps1` |
|------|---------------------------|----------------------------|------------------------|
| **目标用户** | 新手 ⭐ | 高级用户 | 专业用户 |
| **复杂度** | 简单 | 中等 | 简单 |
| **启动服务** | 固定4个服务 | 可选服务组合 | 仅集群服务 |
| **开发容器** | ✅ 包含 | ✅ 包含 | ❌ 不包含 |
| **Jupyter Lab** | ✅ 8888端口 | ✅ 8888端口 | ❌ 无 |
| **可选组件** | ❌ 不支持 | ✅ Kafka/ES/Kibana | ✅ Kafka/ES/Kibana |
| **自动测试** | ✅ -Test参数 | ❌ 无 | ❌ 无 |
| **参数数量** | 3个 | 6个 | 4个 |

## 🎯 使用场景建议

### 场景1: 第一次使用 → `quick_container_start.ps1`
```powershell
.\quick_container_start.ps1 -Test
# 自动测试，确保一切正常
```

### 场景2: 日常学习开发 → `quick_container_start.ps1`
```powershell
.\quick_container_start.ps1
# 简单快速，满足基本需求
```

### 场景3: 需要流处理 → `start_dev_environment.ps1`
```powershell
.\scripts\start_dev_environment.ps1 -Streaming
# 包含 Kafka 用于流处理学习
```

### 场景4: 需要完整分析栈 → `start_dev_environment.ps1`
```powershell
.\scripts\start_dev_environment.ps1 -All
# 包含 Kafka + Elasticsearch + Kibana
```

### 场景5: 本地开发环境 → `start_environment.ps1`
```powershell
.\scripts\start_environment.ps1
# 仅集群，本地 Python 连接
```

## 🔍 详细对比

### 1. `start_environment.ps1` - 仅集群
```powershell
# 启动的服务
- spark-master (端口 8080)
- spark-worker-1 (端口 8081) 
- spark-worker-2 (端口 8082)
- 可选: kafka, elasticsearch 等

# 不包含
❌ spark-dev 开发容器
❌ Jupyter Lab 环境

# 使用场景
✅ 本地 Python 环境连接 Docker 集群
✅ 仅需要 Spark 集群服务
✅ 自定义开发环境
```

### 2. `start_dev_environment.ps1` - 完整开发环境
```powershell
# 启动的服务
- spark-master (端口 8080)
- spark-worker-1 (端口 8081)
- spark-worker-2 (端口 8082)
- spark-dev (端口 8888) ⭐
- 可选: kafka, elasticsearch 等

# 包含
✅ spark-dev 开发容器
✅ Jupyter Lab 环境
✅ 预装 Python 包
✅ 国内镜像源配置

# 使用场景
✅ 容器化开发 (推荐)
✅ 零配置开发环境
✅ 学习和教学
```

### 3. `quick_container_start.ps1` - 一键启动 ⭐
```powershell
# 启动的服务
- spark-master (端口 8080)
- spark-worker-1 (端口 8081)
- spark-worker-2 (端口 8082)
- spark-dev (端口 8888) ⭐

# 特点
✅ 最简单的启动方式
✅ 自动测试环境和网络
✅ 友好的用户界面
✅ 新手推荐
✅ 固定启动基础服务

# 参数
-Test    # 启动后自动运行测试
-Clean   # 清理后重新启动
-Logs    # 显示实时日志

# 与其他脚本的区别
❌ 不支持可选组件 (Kafka, Elasticsearch)
❌ 参数较少，功能简化
✅ 专注于基础开发环境
✅ 包含自动化测试
```

## 💡 使用建议

### 新手用户 (推荐)
```powershell
# 一键启动并测试 ⭐
.\quick_container_start.ps1 -Test

# 清理重启
.\quick_container_start.ps1 -Clean -Test
```

### 日常开发
```powershell
# 基础开发环境 (简单)
.\quick_container_start.ps1

# 完整开发环境 (包含可选组件)
.\scripts\start_dev_environment.ps1 -All

# 仅开发环境 (不含可选组件)
.\scripts\start_dev_environment.ps1 -DevOnly
```

### 高级用户
```powershell
# 仅启动集群，本地开发
.\scripts\start_environment.ps1

# 启动集群 + 流处理组件
.\scripts\start_environment.ps1 -Streaming

# 然后在本地使用 PySpark 连接
# spark = SparkSession.builder.master("spark://localhost:7077").getOrCreate()
```

## 🔧 参数说明

### 通用参数
- `-Streaming` - 启动 Kafka 流处理组件
- `-Analytics` - 启动 Elasticsearch/Kibana 分析组件  
- `-All` - 启动所有可选组件
- `-Force` - 强制清理重建

### 开发环境专用参数
- `-DevOnly` - 仅启动开发必需的服务
- `-Logs` - 显示实时日志

## 🎯 选择指南

**什么时候用 `start_environment.ps1`？**
- 你有本地 Python 环境
- 想要自定义开发工具
- 需要更多的系统资源控制

**什么时候用 `start_dev_environment.ps1`？**
- 想要零配置开发体验 ⭐
- 避免本地环境配置问题
- 团队协作需要统一环境
- 学习和教学场景

**什么时候用 `quick_container_start.ps1`？** ⭐
- 第一次使用项目
- 日常开发 (基础功能足够)
- 快速验证环境
- 不想记复杂命令
- 需要自动化测试

## 🎯 三者关系

```
复杂度和功能：
start_environment.ps1 < quick_container_start.ps1 < start_dev_environment.ps1

推荐使用顺序：
1. quick_container_start.ps1    (大多数用户)
2. start_dev_environment.ps1    (需要完整功能)
3. start_environment.ps1        (仅需集群)
```

总的来说，**`quick_container_start.ps1` 是最佳选择**，简单易用且包含自动测试！