#!/usr/bin/env pwsh
# 构建 Spark 开发环境镜像

param(
    [switch]$Force,     # 强制重新构建
    [switch]$NoCache    # 不使用缓存
)

Write-Host "🔨 构建 Spark 开发环境镜像" -ForegroundColor Green

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

# 检查是否需要构建
$imageName = "spark-dev:latest"
$imageExists = docker images -q $imageName

if ($imageExists -and -not $Force) {
    Write-Host "📦 镜像 $imageName 已存在" -ForegroundColor Yellow
    Write-Host "💡 使用 -Force 参数强制重新构建" -ForegroundColor Cyan
    
    $choice = Read-Host "是否要重新构建镜像？(y/N)"
    if ($choice -ne "y" -and $choice -ne "Y") {
        Write-Host "⏭️  跳过构建" -ForegroundColor Yellow
        exit 0
    }
}

# 构建参数
$buildArgs = @()
if ($NoCache) {
    $buildArgs += "--no-cache"
}

Write-Host "🏗️  开始构建镜像..." -ForegroundColor Cyan
Write-Host "📄 使用 Dockerfile: Dockerfile.spark-dev" -ForegroundColor Gray

# 构建镜像
$buildCommand = "docker build -f Dockerfile.spark-dev -t $imageName . --progress=plain $($buildArgs -join ' ')"
Write-Host "🔧 执行命令: $buildCommand" -ForegroundColor Gray

# 显示构建提示
Write-Host "⏰ 首次构建可能需要几分钟时间，请耐心等待..." -ForegroundColor Yellow
Write-Host "🌐 正在使用国内镜像源加速下载..." -ForegroundColor Cyan

try {
    Invoke-Expression $buildCommand
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 镜像构建成功！" -ForegroundColor Green
        
        # 显示镜像信息
        Write-Host "`n📊 镜像信息:" -ForegroundColor Green
        docker images $imageName
        
        Write-Host "`n💡 使用方法:" -ForegroundColor Green
        Write-Host "  启动环境: .\quick_container_start.ps1" -ForegroundColor Cyan
        Write-Host "  或者:     docker-compose up -d" -ForegroundColor Cyan
        
    } else {
        Write-Host "❌ 镜像构建失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 构建过程中出现错误: $_" -ForegroundColor Red
    exit 1
}