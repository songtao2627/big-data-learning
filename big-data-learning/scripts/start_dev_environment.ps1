#!/usr/bin/env pwsh
# Spark 开发环境启动脚本 (包含开发容器)

param(
    [switch]$Streaming,    # 启动流处理组件 (Kafka)
    [switch]$Analytics,    # 启动分析组件 (Elasticsearch/Kibana)
    [switch]$All,          # 启动所有组件
    [switch]$DevOnly,      # 仅启动开发环境
    [switch]$Force,        # 强制重建
    [switch]$Logs,         # 显示日志
    [switch]$NoCache       # 不使用缓存构建镜像
)

Write-Host "🚀 启动 Spark 开发环境..." -ForegroundColor Green

# 检查 Docker
try {
    docker version | Out-Null
    Write-Host "✅ Docker 运行正常" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker 未运行，请先启动 Docker Desktop" -ForegroundColor Red
    exit 1
}

# 进入项目目录
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Split-Path -Parent $scriptPath
Set-Location $projectPath

# 检查开发镜像是否存在
$devImage = "spark-dev:latest"
$imageExists = docker images -q $devImage

if (-not $imageExists -or $NoCache) {
    Write-Host "📦 开发镜像不存在或需要重新构建..." -ForegroundColor Yellow
    Write-Host "🔨 开始构建 Spark 开发环境镜像..." -ForegroundColor Cyan
    
    $buildArgs = @("build", "-f", "Dockerfile.spark-dev", "-t", $devImage)
    if ($NoCache) {
        $buildArgs += "--no-cache"
        Write-Host "ocache 模式: 使用 --no-cache 选项构建" -ForegroundColor Yellow
    }
    $buildArgs += "."
    
    & docker $buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 镜像构建失败" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ 镜像构建成功" -ForegroundColor Green
} else {
    Write-Host "✅ 开发镜像已存在" -ForegroundColor Green
}

# 构建 docker-compose 命令
$composeCmd = "docker-compose"
$profiles = @()

if ($All) {
    $profiles += "streaming", "analytics"
} else {
    if ($Streaming) { $profiles += "streaming" }
    if ($Analytics) { $profiles += "analytics" }
}

# 添加 profile 参数
if ($profiles.Count -gt 0) {
    foreach ($profile in $profiles) {
        $composeCmd += " --profile $profile"
    }
}

# 强制重建
if ($Force) {
    Write-Host "🔄 停止并清理现有容器..." -ForegroundColor Yellow
    Invoke-Expression "$composeCmd down -v"
    docker system prune -f
}

# 启动服务
if ($DevOnly) {
    Write-Host "🛠️ 启动开发环境 (集群 + 开发容器)..." -ForegroundColor Cyan
    $services = "spark-master spark-worker-1 spark-worker-2 spark-dev"
    Invoke-Expression "$composeCmd up -d $services"
} else {
    Write-Host "🌟 启动完整环境..." -ForegroundColor Cyan
    Invoke-Expression "$composeCmd up -d"
}

# 等待服务启动
Write-Host "⏳ 等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# 检查服务状态
Write-Host "`n📊 服务状态:" -ForegroundColor Green
docker-compose ps

# 显示访问信息
Write-Host "`n🌐 访问地址:" -ForegroundColor Green
Write-Host "  📓 Jupyter Lab:     http://localhost:8888/lab?token=spark-learning" -ForegroundColor Cyan
Write-Host "  🔑 Token:           spark-learning" -ForegroundColor Cyan
Write-Host "  🎯 Spark Master UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  👷 Spark Worker 1:  http://localhost:8081" -ForegroundColor Cyan
Write-Host "  👷 Spark Worker 2:  http://localhost:8082" -ForegroundColor Cyan
Write-Host "  📱 Spark App UI:    http://localhost:4040 (运行作业时可用)" -ForegroundColor Cyan

if ($profiles -contains "streaming") {
    Write-Host "  📨 Kafka:           localhost:9092" -ForegroundColor Cyan
}

if ($profiles -contains "analytics") {
    Write-Host "  🔍 Elasticsearch:   http://localhost:9200" -ForegroundColor Cyan
    Write-Host "  📈 Kibana:          http://localhost:5601" -ForegroundColor Cyan
}

# 显示有用的命令
Write-Host "`n💡 有用的命令:" -ForegroundColor Green
Write-Host "  进入开发容器:    docker exec -it spark-dev bash" -ForegroundColor Yellow
Write-Host "  运行测试:        docker exec -it spark-dev python3 test_container_environment.py" -ForegroundColor Yellow
Write-Host "  查看日志:        docker-compose logs -f spark-dev" -ForegroundColor Yellow
Write-Host "  停止环境:        docker-compose down" -ForegroundColor Yellow
Write-Host "  停止所有服务:    docker-compose stop" -ForegroundColor Yellow
Write-Host "  停止特定服务:    docker-compose stop <service_name>" -ForegroundColor Yellow
Write-Host "  启动所有服务:    docker-compose start" -ForegroundColor Yellow
Write-Host "  启动特定服务:    docker-compose start <service_name>" -ForegroundColor Yellow
Write-Host "  强制重新构建所有镜像：  docker-compose build --no-cache" -ForegroundColor Yellow
Write-Host "  重新构建特定服务：  docker-compose build --no-cache spark-dev" -ForegroundColor Yellow

# 显示日志
if ($Logs) {
    Write-Host "`n📋 实时日志 (Ctrl+C 退出):" -ForegroundColor Green
    docker-compose logs -f spark-dev
}

Write-Host "`n✅ 开发环境启动完成！开始你的 Spark 学习之旅吧！" -ForegroundColor Green