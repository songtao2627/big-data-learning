#!/usr/bin/env pwsh
# 快速启动容器开发环境

# 设置编码以正确显示中文
param(
    [switch]$Test,      # 启动后运行测试
    [switch]$Logs,      # 显示日志
    [switch]$Clean,     # 清理后重新启动
    [switch]$NoCache    # 不使用缓存构建镜像
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "🚀 快速启动 Spark 容器开发环境" -ForegroundColor Green

# 进入项目目录
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# 检查 Docker
try {
    docker version | Out-Null
    Write-Host "✅ Docker 运行正常" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker 未运行，请启动 Docker Desktop" -ForegroundColor Red
    exit 1
}

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

# 清理环境 (如果需要)
if ($Clean) {
    Write-Host "🧹 清理现有环境..." -ForegroundColor Yellow
    docker-compose down -v
    docker system prune -f
}

# 启动开发环境
Write-Host "🔧 启动开发环境..." -ForegroundColor Cyan
docker-compose up -d spark-master spark-worker-1 spark-worker-2 spark-dev

# 等待服务启动
Write-Host "⏳ 等待服务启动 (30秒)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 检查服务状态
Write-Host "`n📊 服务状态:" -ForegroundColor Green
docker-compose ps

# 运行测试 (如果需要)
if ($Test) {
    Write-Host "`n🧪 运行环境测试..." -ForegroundColor Cyan
    docker exec -it spark-dev python3 test_container_environment.py
    
    Write-Host "`n🔍 运行网络连通性测试..." -ForegroundColor Cyan
    docker exec -it spark-dev python3 test_network_connectivity.py
}

# 显示访问信息
Write-Host "`n🌐 访问地址:" -ForegroundColor Green
Write-Host "  📓 Jupyter Lab:     http://localhost:8888/lab?token=spark-learning" -ForegroundColor Cyan
Write-Host "  🔑 Token:           spark-learning" -ForegroundColor Cyan
Write-Host "  🎯 Spark Master UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  � Spark AWorker 1:  http://localhost:8081" -ForegroundColor Cyan
Write-Host "  👷 Spark Worker 2:  http://localhost:8082" -ForegroundColor Cyan
Write-Host "  📱 Spark App UI:    http://localhost:4040 (运行作业时可用)" -ForegroundColor Cyan

Write-Host "`n💡 常用命令:" -ForegroundColor Green
Write-Host "  进入容器:    docker exec -it spark-dev bash" -ForegroundColor Yellow
Write-Host "  运行测试:    docker exec -it spark-dev python3 test_container_environment.py" -ForegroundColor Yellow
Write-Host "  查看日志:    docker-compose logs -f spark-dev" -ForegroundColor Yellow
Write-Host "  停止环境:    docker-compose down" -ForegroundColor Yellow
Write-Host "  强制重新构建所有镜像：  docker-compose build --no-cache" -ForegroundColor Yellow
Write-Host "  重新构建特定服务：  docker-compose build --no-cache spark-dev" -ForegroundColor Yellow
Write-Host "  构建并启动：    docker-compose up --build" -ForegroundColor Yellow
Write-Host "  停止所有服务:  docker-compose stop" -ForegroundColor Yellow
Write-Host "  停止特定服务:  docker-compose stop <service_name>" -ForegroundColor Yellow
Write-Host "  启动所有已停止的服务:  docker-compose start" -ForegroundColor Yellow
Write-Host "  启动特定已停止的服务:  docker-compose start <service_name>" -ForegroundColor Yellow

# 显示日志 (如果需要)
if ($Logs) {
    Write-Host "`n📋 实时日志 (Ctrl+C 退出):" -ForegroundColor Green
    docker-compose logs -f spark-dev
}

Write-Host "`n✅ 环境启动完成！开始你的 Spark 学习之旅吧！" -ForegroundColor Green