# 📜 脚本总览

## 🎯 核心启动脚本对比

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

### 1. `quick_container_start.ps1` ⭐ 推荐
```powershell
# 一键启动基础开发环境
.\quick_container_start.ps1 -Test
```
- **用途**: 新手友好的一键启动
- **包含**: Spark 集群 + 开发容器
- **特点**: 自动测试、简单易用

### 2. `scripts/start_dev_environment.ps1`
```powershell
# 启动完整开发环境
.\scripts\start_dev_environment.ps1 -All
```
- **用途**: 高级用户，完整功能
- **包含**: 集群 + 开发容器 + 可选组件
- **特点**: 参数丰富、功能完整

### 3. `scripts/start_environment.ps1`
```powershell
# 仅启动 Spark 集群
.\scripts\start_environment.ps1
```
- **用途**: 本地开发连接集群
- **包含**: 仅 Spark Master + Workers
- **特点**: 轻量级、无开发容器

## 🛠️ 辅助脚本 (4个)

### 4. `scripts/stop_environment.ps1`
```powershell
# 停止所有服务
.\scripts\stop_environment.ps1
```

### 5. `test_container_environment.py`
```powershell
# 快速环境测试
docker exec -it spark-dev python3 test_container_environment.py
```

### 6. `test_network_connectivity.py`
```powershell
# 详细网络测试
docker exec -it spark-dev python3 test_network_connectivity.py
```

### 7. `scripts/data_generator.py`
```powershell
# 生成示例数据
docker exec -it spark-dev python3 scripts/data_generator.py
```

## 🔧 配置文件 (2个)

### 8. `scripts/spark-defaults.conf`
- Spark 默认配置参数

### 9. `scripts/setup_mirrors.sh`
- 容器内镜像源配置

## 📊 使用统计

```
总脚本数: 9个
├── 启动脚本: 3个 (核心)
├── 测试脚本: 2个 (诊断)
├── 工具脚本: 2个 (辅助)
└── 配置文件: 2个 (配置)
```

## 🎯 推荐使用流程

### 新手用户
```powershell
1. .\quick_container_start.ps1 -Test    # 启动并测试
2. 访问 http://localhost:8888           # 开始学习
3. docker-compose down                  # 停止环境
```

### 日常开发
```powershell
1. .\quick_container_start.ps1          # 启动环境
2. docker exec -it spark-dev bash       # 进入容器
3. .\scripts\stop_environment.ps1       # 停止环境
```

### 高级用户
```powershell
1. .\scripts\start_dev_environment.ps1 -All  # 完整环境
2. 开发和测试...
3. .\scripts\stop_environment.ps1            # 停止环境
```

## 💡 脚本选择指南

**什么时候用哪个脚本？**

| 需求 | 推荐脚本 | 原因 |
|------|----------|------|
| 第一次使用 | `quick_container_start.ps1 -Test` | 自动测试，确保环境正常 |
| 日常学习 | `quick_container_start.ps1` | 简单快速，满足基本需求 |
| 需要 Kafka | `start_dev_environment.ps1 -Streaming` | 支持流处理组件 |
| 需要 ES/Kibana | `start_dev_environment.ps1 -Analytics` | 支持分析组件 |
| 本地开发 | `start_environment.ps1` | 仅集群，本地连接 |
| 环境诊断 | `test_*.py` | 专业的测试工具 |

现在脚本数量精简了很多，每个都有明确的用途！🎉