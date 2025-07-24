# 大数据学习平台环境停止脚本

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "正在停止大数据学习平台环境..." -ForegroundColor Cyan
Write-Host "项目根目录: $projectRoot" -ForegroundColor Cyan

# 检查Docker是否运行
try {
    $dockerStatus = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: Docker未运行，请先启动Docker Desktop" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Docker正在运行" -ForegroundColor Green
} catch {
    Write-Host "错误: 无法执行Docker命令，请确保Docker已安装并运行" -ForegroundColor Red
    exit 1
}

# 切换到项目根目录
Set-Location $projectRoot

# 停止Docker Compose环境
Write-Host "`n正在停止Docker容器..." -ForegroundColor Cyan
try {
    docker-compose down
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: 停止Docker Compose环境失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Docker Compose环境已停止" -ForegroundColor Green
} catch {
    Write-Host "错误: 停止Docker Compose环境时出现异常: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n环境已成功停止！" -ForegroundColor Green