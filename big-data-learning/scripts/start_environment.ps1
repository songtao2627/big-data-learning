#!/usr/bin/env pwsh
# 启动 Spark 集群环境 (不含开发容器)

# 设置编码以正确显示中文
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

param(
    [switch]$Streaming,    # 启动流处理组件
    [switch]$Analytics,    # 启动分析组件
    [switch]$All,          # 启动所有组件
    [switch]$Force,        # 强制重建
    [switch]$NoCache       # 不使用缓存构建镜像
)

Write-Host "🚀 启动 Spark 集群环境..." -ForegroundColor Green

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

# 构建命令
$composeCmd = "docker-compose"
if ($All) {
    $composeCmd += " --profile streaming --profile analytics"
} elseif ($Streaming) {
    $composeCmd += " --profile streaming"
} elseif ($Analytics) {
    $composeCmd += " --profile analytics"
}

# 强制重建
if ($Force) {
    Write-Host "🔄 清理现有环境..." -ForegroundColor Yellow
    Invoke-Expression "$composeCmd down -v"
    docker system prune -f
}

# 启动集群 (不包含开发容器)
Write-Host "🌟 启动 Spark 集群..." -ForegroundColor Cyan
$services = "spark-master spark-worker-1 spark-worker-2"
if ($Streaming) { $services += " zookeeper kafka" }
if ($Analytics) { $services += " elasticsearch kibana" }

Invoke-Expression "$composeCmd up -d $services"

Start-Sleep -Seconds 10
docker-compose ps

Write-Host "`n🌐 访问地址:" -ForegroundColor Green
Write-Host "  🎯 Spark Master UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  👷 Spark Workers:   http://localhost:8081, http://localhost:8082" -ForegroundColor Cyan

if ($Streaming) {
    Write-Host "  📨 Kafka:           localhost:9092" -ForegroundColor Cyan
}

if ($Analytics) {
    Write-Host "  🔍 Elasticsearch:   http://localhost:9200" -ForegroundColor Cyan
    Write-Host "  📈 Kibana:          http://localhost:5601" -ForegroundColor Cyan
}

Write-Host "`n💡 常用命令:" -ForegroundColor Green
Write-Host "  停止环境:        docker-compose down" -ForegroundColor Yellow
Write-Host "  停止所有服务:    docker-compose stop" -ForegroundColor Yellow
Write-Host "  停止特定服务:    docker-compose stop <service_name>" -ForegroundColor Yellow
Write-Host "  启动所有服务:    docker-compose start" -ForegroundColor Yellow
Write-Host "  启动特定服务:    docker-compose start <service_name>" -ForegroundColor Yellow
Write-Host "  强制重新构建所有镜像：  docker-compose build --no-cache" -ForegroundColor Yellow

Write-Host "`n💡 提示: 使用 .\quick_container_start.ps1 启动完整开发环境" -ForegroundColor Yellow