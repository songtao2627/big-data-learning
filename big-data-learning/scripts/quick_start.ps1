# 大数据学习平台一键启动脚本
# 这是最简单的启动方式，适合初学者使用

param(
    [switch]$Help,
    [switch]$Full,
    [switch]$Reset
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# 显示帮助信息
if ($Help) {
    Write-Host "大数据学习平台一键启动脚本" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "用法:" -ForegroundColor White
    Write-Host "  .\quick_start.ps1          # 启动基础环境 (Spark + Jupyter)"
    Write-Host "  .\quick_start.ps1 -Full    # 启动完整环境 (包含Kafka, Elasticsearch等)"
    Write-Host "  .\quick_start.ps1 -Reset   # 重置并启动环境"
    Write-Host "  .\quick_start.ps1 -Help    # 显示此帮助信息"
    Write-Host ""
    Write-Host "启动后可访问:" -ForegroundColor White
    Write-Host "  • Jupyter Notebook: http://localhost:8888"
    Write-Host "  • Spark Master UI: http://localhost:8080"
    Write-Host "  • Spark Worker UI: http://localhost:8081, 8082"
    Write-Host ""
    exit 0
}

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    大数据学习平台一键启动" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# 检查Docker状态
Write-Host "正在检查Docker状态..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker未运行" -ForegroundColor Red
        Write-Host "请先启动Docker Desktop，然后重新运行此脚本" -ForegroundColor Yellow
        Write-Host "下载地址: https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "✅ Docker运行正常" -ForegroundColor Green
} catch {
    Write-Host "❌ 无法检测Docker状态" -ForegroundColor Red
    Write-Host "请确保Docker Desktop已安装并运行" -ForegroundColor Yellow
    exit 1
}

# 切换到项目目录
Set-Location $projectRoot
Write-Host "项目目录: $projectRoot" -ForegroundColor Gray

# 检查是否需要重置环境
if ($Reset) {
    Write-Host "`n正在重置环境..." -ForegroundColor Yellow
    Write-Host "停止现有容器..." -ForegroundColor Gray
    docker-compose down -v 2>&1 | Out-Null
    
    Write-Host "清理Docker资源..." -ForegroundColor Gray
    docker system prune -f 2>&1 | Out-Null
    
    Write-Host "✅ 环境重置完成" -ForegroundColor Green
}

# 检查现有容器状态
Write-Host "`n检查现有容器状态..." -ForegroundColor Yellow
$runningContainers = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String -Pattern "(jupyter-notebook|spark-master|spark-worker)"

if ($runningContainers) {
    Write-Host "发现运行中的容器:" -ForegroundColor Cyan
    $runningContainers | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    
    $response = Read-Host "`n是否要重启这些容器? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "正在停止现有容器..." -ForegroundColor Yellow
        docker-compose down 2>&1 | Out-Null
        Write-Host "✅ 现有容器已停止" -ForegroundColor Green
    }
}

# 构建启动参数
$startArgs = @()
if ($Full) {
    $startArgs += "-All"
    Write-Host "`n🚀 启动完整环境 (包含流处理和分析组件)" -ForegroundColor Cyan
} else {
    Write-Host "`n🚀 启动基础环境 (Spark + Jupyter)" -ForegroundColor Cyan
}

# 启动环境
Write-Host "`n正在启动Docker容器..." -ForegroundColor Yellow
try {
    & "$projectRoot\scripts\start_environment.ps1" @startArgs -NoBrowser
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ 环境启动成功!" -ForegroundColor Green
        
        # 等待服务完全启动
        Write-Host "`n等待服务完全启动..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # 获取Jupyter访问链接
        Write-Host "正在获取Jupyter访问信息..." -ForegroundColor Yellow
        $maxRetries = 10
        $retryCount = 0
        $jupyterUrl = $null
        
        while ($retryCount -lt $maxRetries -and -not $jupyterUrl) {
            try {
                $logs = docker logs jupyter-notebook 2>&1
                $tokenMatch = $logs | Select-String -Pattern "http://127\.0\.0\.1:8888/\?token=([a-z0-9]+)" -AllMatches
                
                if ($tokenMatch.Matches.Count -gt 0) {
                    $token = $tokenMatch.Matches[-1].Groups[1].Value
                    $jupyterUrl = "http://localhost:8888/?token=$token"
                    break
                }
            } catch {
                # 忽略错误，继续重试
            }
            
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "  等待Jupyter启动... ($retryCount/$maxRetries)" -ForegroundColor Gray
                Start-Sleep -Seconds 3
            }
        }
        
        # 显示访问信息
        Write-Host "`n===========================================" -ForegroundColor Cyan
        Write-Host "    🎉 环境启动完成!" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Cyan
        
        Write-Host "`n📚 学习资源访问链接:" -ForegroundColor White
        if ($jupyterUrl) {
            Write-Host "  • Jupyter Notebook: $jupyterUrl" -ForegroundColor Cyan
        } else {
            Write-Host "  • Jupyter Notebook: http://localhost:8888 (请查看容器日志获取token)" -ForegroundColor Yellow
        }
        Write-Host "  • Spark Master UI: http://localhost:8080" -ForegroundColor Cyan
        Write-Host "  • Spark Worker 1 UI: http://localhost:8081" -ForegroundColor Cyan
        Write-Host "  • Spark Worker 2 UI: http://localhost:8082" -ForegroundColor Cyan
        
        if ($Full) {
            Write-Host "`n🔧 额外组件:" -ForegroundColor White
            Write-Host "  • Elasticsearch: http://localhost:9200" -ForegroundColor Cyan
            Write-Host "  • Kibana: http://localhost:5601" -ForegroundColor Cyan
            Write-Host "  • Kafka: localhost:9092" -ForegroundColor Cyan
        }
        
        Write-Host "`n🛠️ 常用命令:" -ForegroundColor White
        Write-Host "  • 停止环境: docker-compose down" -ForegroundColor Gray
        Write-Host "  • 查看状态: scripts\health_check.ps1" -ForegroundColor Gray
        Write-Host "  • 查看日志: docker-compose logs -f [服务名]" -ForegroundColor Gray
        Write-Host "  • 重启环境: scripts\quick_start.ps1 -Reset" -ForegroundColor Gray
        
        Write-Host "`n📖 学习建议:" -ForegroundColor White
        Write-Host "  1. 从 '00-welcome.ipynb' 开始" -ForegroundColor Gray
        Write-Host "  2. 按照 'learning_path.md' 的指导学习" -ForegroundColor Gray
        Write-Host "  3. 遇到问题查看 'debugging-guide.md'" -ForegroundColor Gray
        
        # 尝试自动打开浏览器
        if ($jupyterUrl) {
            $openBrowser = Read-Host "`n是否要在浏览器中打开Jupyter Notebook? (Y/n)"
            if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
                try {
                    Start-Process $jupyterUrl
                    Write-Host "✅ 已在浏览器中打开Jupyter Notebook" -ForegroundColor Green
                } catch {
                    Write-Host "⚠️ 无法自动打开浏览器，请手动访问上面的链接" -ForegroundColor Yellow
                }
            }
        }
        
        Write-Host "`n🚀 开始您的大数据学习之旅吧!" -ForegroundColor Green
        
    } else {
        Write-Host "`n❌ 环境启动失败" -ForegroundColor Red
        Write-Host "请检查Docker状态和网络连接" -ForegroundColor Yellow
        Write-Host "运行 'docker-compose logs' 查看详细错误信息" -ForegroundColor Gray
        exit 1
    }
    
} catch {
    Write-Host "`n❌ 启动过程中出现错误: $_" -ForegroundColor Red
    Write-Host "请尝试以下解决方案:" -ForegroundColor Yellow
    Write-Host "  1. 重启Docker Desktop" -ForegroundColor Gray
    Write-Host "  2. 运行 'scripts\quick_start.ps1 -Reset' 重置环境" -ForegroundColor Gray
    Write-Host "  3. 检查端口是否被占用 (8888, 8080, 8081, 8082)" -ForegroundColor Gray
    exit 1
}