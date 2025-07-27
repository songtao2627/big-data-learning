# Docker 容器网络故障排除指南

## 🔍 网络配置概览

### IP 地址分配
```
网络: spark-learning-network (172.20.0.0/16)

核心服务:
├── spark-master     172.20.0.10:7077
├── spark-worker-1   172.20.0.11:8881
├── spark-worker-2   172.20.0.12:8882
└── spark-dev        172.20.0.20:8888

流处理组件:
├── zookeeper        172.20.0.30:2181
└── kafka            172.20.0.31:9092

分析组件:
├── elasticsearch    172.20.0.40:9200
└── kibana           172.20.0.41:5601
```

## 🧪 网络测试命令

### 1. 基本连通性测试
```bash
# 在任意容器内执行
docker exec -it spark-dev python3 test_network_connectivity.py

# 或者快速测试
docker exec -it spark-dev python3 test_container_environment.py
```

### 2. 手动网络诊断
```bash
# 进入开发容器
docker exec -it spark-dev bash

# 测试 DNS 解析
nslookup spark-master
nslookup spark-worker-1
nslookup spark-worker-2

# 测试端口连通性
telnet spark-master 7077
telnet spark-worker-1 8881
telnet spark-worker-2 8882

# 测试 ping 连通性
ping -c 3 spark-master
ping -c 3 spark-worker-1
ping -c 3 spark-worker-2
```

### 3. Docker 网络检查
```powershell
# 查看网络列表
docker network ls

# 检查网络详情
docker network inspect spark-learning-network

# 查看容器网络配置
docker inspect spark-master | grep -A 20 NetworkSettings
docker inspect spark-dev | grep -A 20 NetworkSettings
```

## ❌ 常见网络问题

### 问题 1: DNS 解析失败
**症状**: 容器无法通过主机名访问其他容器
```
❌ spark-master -> DNS 解析失败
```

**解决方案**:
```bash
# 1. 重启 Docker 网络
docker-compose down
docker network prune -f
docker-compose up -d

# 2. 检查容器是否在同一网络
docker network inspect spark-learning-network
```

### 问题 2: 端口连接被拒绝
**症状**: 端口无法连接
```
❌ Spark Master: spark-master:7077 - 连接失败
```

**解决方案**:
```bash
# 1. 检查服务是否启动
docker-compose ps

# 2. 查看服务日志
docker-compose logs spark-master

# 3. 检查端口监听
docker exec -it spark-master netstat -tlnp | grep 7077
```

### 问题 3: 容器启动顺序问题
**症状**: Worker 无法连接到 Master
```
❌ spark-worker-1 启动失败
```

**解决方案**:
```bash
# 1. 按顺序重启
docker-compose stop
docker-compose up -d spark-master
# 等待 30 秒
docker-compose up -d spark-worker-1 spark-worker-2
docker-compose up -d spark-dev
```

### 问题 4: 防火墙或安全软件干扰
**症状**: 间歇性连接失败

**解决方案**:
```bash
# 1. 临时关闭防火墙测试
# Windows: 关闭 Windows Defender 防火墙
# macOS: 系统偏好设置 -> 安全性与隐私 -> 防火墙

# 2. 添加 Docker 网络到防火墙白名单
# 网络范围: 172.20.0.0/16
```

### 问题 5: Docker Desktop 网络问题
**症状**: 所有容器网络都有问题

**解决方案**:
```bash
# 1. 重启 Docker Desktop
# 右键 Docker Desktop 图标 -> Restart

# 2. 重置 Docker 网络
docker system prune -a --volumes
# 注意: 这会删除所有未使用的资源

# 3. 检查 Docker Desktop 设置
# Settings -> Resources -> Network
# 确保没有网络冲突
```

## 🔧 网络优化建议

### 1. 资源分配
```yaml
# 在 docker-compose.yml 中为每个服务设置资源限制
services:
  spark-master:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### 2. 健康检查优化
```yaml
# 调整健康检查参数
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080"]
  interval: 15s      # 减少检查频率
  timeout: 10s       # 增加超时时间
  retries: 3         # 减少重试次数
  start_period: 60s  # 增加启动等待时间
```

### 3. 网络性能调优
```yaml
networks:
  spark-network:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1500
      com.docker.network.bridge.enable_icc: "true"
      com.docker.network.bridge.enable_ip_masquerade: "true"
```

## 📊 网络监控

### 实时监控命令
```bash
# 监控网络连接
docker exec -it spark-dev watch -n 2 'netstat -tuln'

# 监控容器资源使用
docker stats

# 监控网络流量
docker exec -it spark-dev iftop -i eth0
```

### 日志分析
```bash
# 查看网络相关日志
docker-compose logs | grep -i "network\|connection\|timeout"

# 查看 Spark 集群日志
docker-compose logs spark-master | grep -i "worker\|connection"
docker-compose logs spark-worker-1 | grep -i "master\|connection"
```

## 🚨 紧急恢复步骤

如果网络完全无法工作：

```bash
# 1. 完全停止环境
docker-compose down -v

# 2. 清理网络资源
docker network prune -f
docker system prune -f

# 3. 重新创建网络
docker network create --driver bridge --subnet=172.20.0.0/16 spark-learning-network

# 4. 重新启动环境
docker-compose up -d

# 5. 验证网络
docker exec -it spark-dev python3 test_network_connectivity.py
```

## 💡 预防措施

1. **定期测试**: 每次启动环境后运行网络测试
2. **监控日志**: 关注容器启动日志中的网络错误
3. **资源管理**: 确保 Docker Desktop 有足够的内存和 CPU
4. **版本兼容**: 保持 Docker 和 Docker Compose 版本更新
5. **网络隔离**: 避免与其他 Docker 网络冲突

通过这些措施，可以确保容器间网络通信的稳定性和可靠性！