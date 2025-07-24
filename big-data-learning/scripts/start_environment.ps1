# 大数据学习平台环境启动脚本

param(
    [switch]$Streaming,
    [switch]$Analytics,
    [switch]$All,
    [switch]$Force,
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    大数据学习平台环境启动" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "项目根目录: $projectRoot" -ForegroundColor Gray

# 检查Docker是否运行
Write-Host "`n检查Docker状态..." -ForegroundColor Yellow
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

# 检查是否需要强制重启
if ($Force) {
    Write-Host "`n强制停止现有容器..." -ForegroundColor Yellow
    docker-compose down
    Write-Host "✓ 现有容器已停止" -ForegroundColor Green
}

# 构建启动命令
$composeArgs = @("up", "-d")
$profiles = @()

if ($Streaming -or $All) {
    $profiles += "streaming"
    Write-Host "启用流处理组件 (Kafka, Zookeeper)" -ForegroundColor Cyan
}

if ($Analytics -or $All) {
    $profiles += "analytics"
    Write-Host "启用分析组件 (Elasticsearch, Kibana)" -ForegroundColor Cyan
}

if ($profiles.Count -gt 0) {
    $profileString = $profiles -join ","
    $composeArgs += "--profile"
    $composeArgs += $profileString
}

# 启动Docker Compose环境
Write-Host "`n正在启动Docker容器..." -ForegroundColor Yellow
Write-Host "执行命令: docker-compose $($composeArgs -join ' ')" -ForegroundColor Gray

try {
    & docker-compose @composeArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: 启动Docker Compose环境失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Docker Compose环境启动成功" -ForegroundColor Green
} catch {
    Write-Host "错误: 启动Docker Compose环境时出现异常: $_" -ForegroundColor Red
    exit 1
}

# 等待容器启动
Write-Host "`n等待容器启动完成..." -ForegroundColor Yellow
$waitTime = 60
for ($i = $waitTime; $i -gt 0; $i--) {
    Write-Progress -Activity "等待服务启动" -Status "剩余时间: $i 秒" -PercentComplete ((($waitTime - $i) / $waitTime) * 100)
    Start-Sleep -Seconds 1
}
Write-Progress -Activity "等待服务启动" -Completed

# 获取Jupyter Notebook的访问令牌
Write-Host "`n正在获取Jupyter Notebook访问信息..." -ForegroundColor Yellow
try {
    $maxRetries = 5
    $retryCount = 0
    $token = $null
    
    while ($retryCount -lt $maxRetries -and -not $token) {
        $logs = docker logs jupyter-notebook 2>&1
        $tokenMatch = $logs | Select-String -Pattern "token=([a-z0-9]+)" -AllMatches
        
        if ($tokenMatch.Matches.Count -gt 0) {
            $token = $tokenMatch.Matches[-1].Groups[1].Value
            break
        }
        
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "等待Jupyter启动... (尝试 $retryCount/$maxRetries)" -ForegroundColor Gray
            Start-Sleep -Seconds 5
        }
    }
    
    if ($token) {
        Write-Host "✓ 获取到Jupyter访问令牌: $token" -ForegroundColor Green
        
        # 构建完整的访问URL
        $jupyterUrl = "http://localhost:8888/?token=$token"
        Write-Host "Jupyter Notebook访问链接: $jupyterUrl" -ForegroundColor Cyan
        
        # 尝试自动打开浏览器
        if (-not $NoBrowser) {
            Write-Host "`n正在尝试打开浏览器..." -ForegroundColor Yellow
            try {
                Start-Process $jupyterUrl
                Write-Host "✓ 已在浏览器中打开Jupyter Notebook" -ForegroundColor Green
            } catch {
                Write-Host "✗ 无法自动打开浏览器，请手动访问上面的链接" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "✗ 无法获取Jupyter访问令牌，请等待几秒后手动查看容器日志" -ForegroundColor Yellow
        Write-Host "运行 'docker logs jupyter-notebook' 查看详细信息" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ 获取Jupyter日志时出错: $_" -ForegroundColor Red
}

# 运行健康检查
Write-Host "`n正在运行环境健康检查..." -ForegroundColor Yellow
try {
    $healthArgs = @()
    if ($Streaming -or $All) { $healthArgs += "-Streaming" }
    if ($Analytics -or $All) { $healthArgs += "-Analytics" }
    
    & "$projectRoot\scripts\health_check.ps1" @healthArgs
} catch {
    Write-Host "✗ 健康检查脚本执行失败: $_" -ForegroundColor Red
}

Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "    环境启动完成!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan

Write-Host "`n访问链接:" -ForegroundColor White
Write-Host "• Jupyter Notebook: http://localhost:8888" -ForegroundColor Cyan
Write-Host "• Spark Master UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "• Spark Worker 1 UI: http://localhost:8081" -ForegroundColor Cyan
Write-Host "• Spark Worker 2 UI: http://localhost:8082" -ForegroundColor Cyan

if ($Streaming -or $All) {
    Write-Host "• Kafka (端口 9092)" -ForegroundColor Cyan
}

if ($Analytics -or $All) {
    Write-Host "• Elasticsearch: http://localhost:9200" -ForegroundColor Cyan
    Write-Host "• Kibana: http://localhost:5601" -ForegroundColor Cyan
}

Write-Host "`n常用命令:" -ForegroundColor White
Write-Host "• 停止环境: docker-compose down" -ForegroundColor Gray
Write-Host "• 查看日志: docker-compose logs -f" -ForegroundColor Gray
Write-Host "• 健康检查: scripts\health_check.ps1" -ForegroundColor Gray
Write-Host "• 重启环境: scripts\start_environment.ps1 -Force" -ForegroundColor Gray

Write-Host "`n开始学习大数据技术吧! 🚀" -ForegroundColor Green