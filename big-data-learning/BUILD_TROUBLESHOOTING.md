# Docker 镜像构建故障排除指南

## 常见问题和解决方案

### 1. apt-get update 速度慢

**问题**: `apt-get update` 步骤耗时很长（几分钟到十几分钟）

**原因**: 
- 默认使用国外软件源
- 网络延迟高
- 包索引文件较大

**解决方案**:
```dockerfile
# 已在 Dockerfile 中添加国内镜像源
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list
```

**临时解决方案**:
```powershell
# 如果仍然很慢，可以尝试其他镜像源
# 编辑 Dockerfile.spark-dev，将 mirrors.aliyun.com 替换为：
# - mirrors.tuna.tsinghua.edu.cn  (清华源)
# - mirrors.ustc.edu.cn          (中科大源)
# - mirrors.163.com              (网易源)
```

### 2. pip 安装包速度慢

**问题**: Python 包安装缓慢

**解决方案**: 已配置清华大学 PyPI 镜像源
```dockerfile
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

### 3. 构建上下文过大

**问题**: `Sending build context to Docker daemon` 步骤很慢

**解决方案**: 已创建 `.dockerignore` 文件排除不必要的文件

### 4. 内存不足

**问题**: 构建过程中出现内存错误

**解决方案**:
```powershell
# 增加 Docker Desktop 内存限制
# 设置 -> Resources -> Memory: 至少 4GB
```

### 5. 用户权限问题

**问题**: `unable to find user spark: no matching entries in passwd file`

**原因**: Bitnami 镜像中的用户管理机制特殊，需要使用数字 UID

**解决方案**: 已修复，使用 `USER 1001` 而不是 `USER spark`

### 6. 网络连接问题

**问题**: 下载包时网络超时

**解决方案**:
```powershell
# 重试构建
.\build_dev_image.ps1 -Force

# 或者使用代理（如果有）
docker build --build-arg HTTP_PROXY=http://proxy:port -f Dockerfile.spark-dev -t spark-dev:latest .
```

## 构建优化技巧

### 1. 使用构建缓存
```powershell
# 正常构建（使用缓存）
.\build_dev_image.ps1

# 强制重新构建（不使用缓存）
.\build_dev_image.ps1 -NoCache
```

### 2. 分层构建策略
Dockerfile 已按照最佳实践组织：
1. 基础镜像和用户切换
2. 系统包安装（变化较少）
3. Python 包安装（变化较多）
4. 配置文件创建（经常变化）

### 3. 并行构建
```powershell
# 使用 BuildKit 加速构建
$env:DOCKER_BUILDKIT=1
docker build -f Dockerfile.spark-dev -t spark-dev:latest .
```

## 监控构建进度

### 1. 详细输出
```powershell
# 显示详细构建过程
docker build -f Dockerfile.spark-dev -t spark-dev:latest . --progress=plain
```

### 2. 构建时间估算
- **首次构建**: 5-15 分钟（取决于网络速度）
- **增量构建**: 1-3 分钟（利用缓存）
- **仅配置更改**: 30 秒内

### 3. 各步骤预期时间
1. 基础镜像拉取: 1-2 分钟
2. apt-get update: 2-5 分钟
3. 系统包安装: 1-2 分钟
4. Python 包安装: 2-4 分钟
5. 配置文件创建: 10-30 秒

## 如果构建仍然很慢

### 方案1: 使用预构建镜像
```yaml
# 在 docker-compose.yml 中临时使用官方镜像
spark-dev:
  image: jupyter/pyspark-notebook:latest
  # 注释掉 build 部分
```

### 方案2: 分步构建
```powershell
# 先构建基础镜像
docker build --target base -f Dockerfile.spark-dev -t spark-dev-base .

# 再构建完整镜像
docker build -f Dockerfile.spark-dev -t spark-dev:latest .
```

### 方案3: 使用多阶段构建
可以考虑将 Dockerfile 改为多阶段构建，但当前单阶段已经足够高效。

## 验证构建结果

```powershell
# 检查镜像大小
docker images spark-dev:latest

# 测试容器启动
docker run --rm -it spark-dev:latest python --version

# 测试 Jupyter 启动
docker run --rm -p 8888:8888 spark-dev:latest jupyter --version
```