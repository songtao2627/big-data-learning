# 大数据学习平台环境健康检查脚本
# 用于检查Docker容器是否正常运行

param(
    [switch]$Detailed,
    [switch]$Streaming,
    [switch]$Analytics,
    [switch]$Quick,
    [switch]$Json
)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    大数据学习平台环境健康检查" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

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

# 获取容器状态
$coreContainers = @(
    @{Name="jupyter-notebook"; Port=8888; Description="Jupyter Notebook"},
    @{Name="spark-master"; Port=8080; Description="Spark Master"},
    @{Name="spark-worker-1"; Port=8081; Description="Spark Worker 1"},
    @{Name="spark-worker-2"; Port=8082; Description="Spark Worker 2"}
)

$streamingContainers = @(
    @{Name="zookeeper"; Port=2181; Description="Zookeeper"},
    @{Name="kafka"; Port=9092; Description="Kafka"}
)

$analyticsContainers = @(
    @{Name="elasticsearch"; Port=9200; Description="Elasticsearch"},
    @{Name="kibana"; Port=5601; Description="Kibana"}
)

$containersToCheck = $coreContainers
if ($Streaming) { $containersToCheck += $streamingContainers }
if ($Analytics) { $containersToCheck += $analyticsContainers }

$allRunning = $true
$runningContainers = @()

Write-Host "`n检查容器状态..." -ForegroundColor Yellow

foreach ($container in $containersToCheck) {
    $status = docker ps -f "name=$($container.Name)" --format "{{.Status}}" 2>&1
    
    if ($status -match "Up") {
        Write-Host "✓ $($container.Description) ($($container.Name)) 正在运行" -ForegroundColor Green
        $runningContainers += $container
        
        if ($Detailed) {
            $health = docker inspect $container.Name --format='{{.State.Health.Status}}' 2>&1
            if ($health -eq "healthy") {
                Write-Host "  健康状态: 健康" -ForegroundColor Green
            } elseif ($health -eq "unhealthy") {
                Write-Host "  健康状态: 不健康" -ForegroundColor Red
            } else {
                Write-Host "  健康状态: 未配置" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "✗ $($container.Description) ($($container.Name)) 未运行" -ForegroundColor Red
        $allRunning = $false
    }
}

# 检查服务可访问性
if ($allRunning) {
    Write-Host "`n正在检查服务可访问性..." -ForegroundColor Cyan
    
    # 检查Jupyter Notebook
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8888" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Jupyter Notebook 可访问: http://localhost:8888" -ForegroundColor Green
        } else {
            Write-Host "✗ Jupyter Notebook 返回状态码: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ 无法访问Jupyter Notebook: http://localhost:8888" -ForegroundColor Red
    }
    
    # 检查Spark Master UI
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Spark Master UI 可访问: http://localhost:8080" -ForegroundColor Green
        } else {
            Write-Host "✗ Spark Master UI 返回状态码: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ 无法访问Spark Master UI: http://localhost:8080" -ForegroundColor Red
    }
    
    # 检查Spark Worker 1 UI
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8081" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Spark Worker 1 UI 可访问: http://localhost:8081" -ForegroundColor Green
        } else {
            Write-Host "✗ Spark Worker 1 UI 返回状态码: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ 无法访问Spark Worker 1 UI: http://localhost:8081" -ForegroundColor Red
    }
    
    # 检查Spark Worker 2 UI
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8082" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Spark Worker 2 UI 可访问: http://localhost:8082" -ForegroundColor Green
        } else {
            Write-Host "✗ Spark Worker 2 UI 返回状态码: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ 无法访问Spark Worker 2 UI: http://localhost:8082" -ForegroundColor Red
    }
}

# 生成健康检查报告
$healthReport = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    overall_status = if ($allRunning) { "healthy" } else { "unhealthy" }
    containers = @()
    services = @()
    recommendations = @()
}

foreach ($container in $containersToCheck) {
    $status = docker ps -f "name=$($container.Name)" --format "{{.Status}}" 2>&1
    $isRunning = $status -match "Up"
    
    $containerInfo = @{
        name = $container.Name
        description = $container.Description
        status = if ($isRunning) { "running" } else { "stopped" }
        port = $container.Port
    }
    
    $healthReport.containers += $containerInfo
}

# 添加服务状态到报告
foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        $serviceInfo = @{
            name = $service.Name
            url = $service.Url
            status = if ($response.StatusCode -eq $service.ExpectedStatus) { "accessible" } else { "error" }
            status_code = $response.StatusCode
        }
    } catch {
        $serviceInfo = @{
            name = $service.Name
            url = $service.Url
            status = "inaccessible"
            error = $_.Exception.Message
        }
    }
    
    $healthReport.services += $serviceInfo
}

# 添加建议
if (-not $allRunning) {
    $healthReport.recommendations += "运行 'scripts\quick_start.ps1' 启动环境"
    $healthReport.recommendations += "检查Docker Desktop是否正常运行"
    $healthReport.recommendations += "运行 'scripts\troubleshoot.ps1 -Auto' 进行自动诊断"
}

# 输出结果
if ($Json) {
    $healthReport | ConvertTo-Json -Depth 3
} else {
    Write-Host "`n健康检查完成" -ForegroundColor Cyan
    if ($allRunning) {
        Write-Host "环境状态: 正常 ✅" -ForegroundColor Green
        Write-Host "`n访问链接:" -ForegroundColor Cyan
        Write-Host "- Jupyter Notebook: http://localhost:8888" -ForegroundColor White
        Write-Host "- Spark Master UI: http://localhost:8080" -ForegroundColor White
        Write-Host "- Spark Worker 1 UI: http://localhost:8081" -ForegroundColor White
        Write-Host "- Spark Worker 2 UI: http://localhost:8082" -ForegroundColor White
        
        if ($Streaming) {
            Write-Host "- Kafka: localhost:9092" -ForegroundColor White
        }
        
        if ($Analytics) {
            Write-Host "- Elasticsearch: http://localhost:9200" -ForegroundColor White
            Write-Host "- Kibana: http://localhost:5601" -ForegroundColor White
        }
        
        Write-Host "`n🚀 环境已就绪，可以开始学习!" -ForegroundColor Green
        
    } else {
        Write-Host "环境状态: 异常 ❌" -ForegroundColor Red
        Write-Host "`n建议的解决方案:" -ForegroundColor Yellow
        foreach ($recommendation in $healthReport.recommendations) {
            Write-Host "  • $recommendation" -ForegroundColor Gray
        }
    }
    
    if ($Quick) {
        # 快速模式，只显示基本状态
        return
    }
    
    Write-Host "`n💡 提示:" -ForegroundColor Cyan
    Write-Host "  • 运行 'scripts\verify_environment.ps1' 进行完整验证" -ForegroundColor Gray
    Write-Host "  • 运行 'scripts\troubleshoot.ps1' 获取故障排除帮助" -ForegroundColor Gray
    Write-Host "  • 查看 'README.md' 了解更多使用说明" -ForegroundColor Gray
}