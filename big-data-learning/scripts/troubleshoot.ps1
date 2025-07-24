# 大数据学习平台故障排除脚本
# 用于诊断和解决常见问题

param(
    [switch]$Auto,
    [switch]$Reset,
    [switch]$CleanAll,
    [string]$Issue = ""
)

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    大数据学习平台故障排除" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# 常见问题和解决方案
$commonIssues = @{
    "port" = @{
        Name = "端口占用问题"
        Description = "8888, 8080, 8081, 8082端口被占用"
        Solutions = @(
            "检查端口占用情况",
            "停止占用端口的程序",
            "修改docker-compose.yml中的端口映射"
        )
    }
    "docker" = @{
        Name = "Docker相关问题"
        Description = "Docker未启动或配置问题"
        Solutions = @(
            "启动Docker Desktop",
            "检查Docker资源配置",
            "重启Docker服务"
        )
    }
    "memory" = @{
        Name = "内存不足问题"
        Description = "系统内存不足导致容器启动失败"
        Solutions = @(
            "关闭不必要的程序",
            "增加Docker内存限制",
            "减少Spark Worker数量"
        )
    }
    "network" = @{
        Name = "网络连接问题"
        Description = "无法访问Web界面或服务"
        Solutions = @(
            "检查防火墙设置",
            "验证端口映射",
            "重启网络服务"
        )
    }
    "jupyter" = @{
        Name = "Jupyter Notebook问题"
        Description = "无法访问或启动Jupyter"
        Solutions = @(
            "检查容器日志",
            "重新获取访问token",
            "重启Jupyter容器"
        )
    }
    "spark" = @{
        Name = "Spark连接问题"
        Description = "无法连接到Spark集群"
        Solutions = @(
            "检查Spark Master状态",
            "验证Worker连接",
            "重启Spark服务"
        )
    }
}

# 显示可用的故障排除选项
function Show-TroubleshootMenu {
    Write-Host "`n🔧 故障排除选项:" -ForegroundColor Cyan
    Write-Host "1. 自动诊断 (推荐)" -ForegroundColor White
    Write-Host "2. 端口占用检查" -ForegroundColor White
    Write-Host "3. Docker状态检查" -ForegroundColor White
    Write-Host "4. 容器日志查看" -ForegroundColor White
    Write-Host "5. 网络连接测试" -ForegroundColor White
    Write-Host "6. 重置环境" -ForegroundColor White
    Write-Host "7. 完全清理" -ForegroundColor White
    Write-Host "8. 查看常见问题" -ForegroundColor White
    Write-Host "0. 退出" -ForegroundColor Gray
    Write-Host ""
}

# 自动诊断功能
function Start-AutoDiagnosis {
    Write-Host "`n🔍 开始自动诊断..." -ForegroundColor Yellow
    
    $issues = @()
    
    # 检查Docker状态
    Write-Host "检查Docker状态..." -ForegroundColor Gray
    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $issues += "Docker未运行"
        } else {
            Write-Host "✅ Docker运行正常" -ForegroundColor Green
        }
    } catch {
        $issues += "Docker命令执行失败"
    }
    
    # 检查端口占用
    Write-Host "检查端口占用..." -ForegroundColor Gray
    $ports = @(8888, 8080, 8081, 8082)
    foreach ($port in $ports) {
        $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($connection -and $connection.State -eq "Listen") {
            $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
            if ($process -and $process.ProcessName -notmatch "docker") {
                $issues += "端口 $port 被进程 $($process.ProcessName) 占用"
            }
        }
    }
    
    # 检查容器状态
    Write-Host "检查容器状态..." -ForegroundColor Gray
    $requiredContainers = @("jupyter-notebook", "spark-master", "spark-worker-1", "spark-worker-2")
    foreach ($container in $requiredContainers) {
        $status = docker ps -f "name=$container" --format "{{.Status}}" 2>&1
        if (-not ($status -match "Up")) {
            $issues += "容器 $container 未运行"
        }
    }
    
    # 检查系统资源
    Write-Host "检查系统资源..." -ForegroundColor Gray
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    if ($freeMemoryGB -lt 2) {
        $issues += "可用内存不足 (当前: $freeMemoryGB GB)"
    }
    
    # 显示诊断结果
    if ($issues.Count -eq 0) {
        Write-Host "`n✅ 自动诊断完成，未发现明显问题" -ForegroundColor Green
        Write-Host "如果仍有问题，请尝试手动诊断选项" -ForegroundColor Gray
    } else {
        Write-Host "`n❌ 发现以下问题:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  • $issue" -ForegroundColor Yellow
        }
        
        Write-Host "`n🔧 建议的解决方案:" -ForegroundColor Cyan
        if ($issues -match "Docker") {
            Write-Host "  1. 启动Docker Desktop" -ForegroundColor White
            Write-Host "  2. 检查Docker资源配置" -ForegroundColor White
        }
        if ($issues -match "端口.*占用") {
            Write-Host "  3. 停止占用端口的程序" -ForegroundColor White
            Write-Host "  4. 或修改端口配置" -ForegroundColor White
        }
        if ($issues -match "容器.*未运行") {
            Write-Host "  5. 运行 'scripts\quick_start.ps1' 启动环境" -ForegroundColor White
        }
        if ($issues -match "内存不足") {
            Write-Host "  6. 关闭不必要的程序释放内存" -ForegroundColor White
        }
    }
}

# 检查端口占用
function Check-PortUsage {
    Write-Host "`n🔍 检查端口占用情况..." -ForegroundColor Yellow
    
    $ports = @(8888, 8080, 8081, 8082, 9092, 9200, 5601)
    $portInfo = @()
    
    foreach ($port in $ports) {
        try {
            $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            if ($connections) {
                foreach ($conn in $connections) {
                    if ($conn.State -eq "Listen") {
                        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                        $portInfo += @{
                            Port = $port
                            Process = if ($process) { $process.ProcessName } else { "Unknown" }
                            PID = $conn.OwningProcess
                            State = $conn.State
                        }
                    }
                }
            }
        } catch {
            # 端口未被占用或无法访问
        }
    }
    
    if ($portInfo.Count -eq 0) {
        Write-Host "✅ 所有检查的端口都未被占用" -ForegroundColor Green
    } else {
        Write-Host "📋 端口占用情况:" -ForegroundColor Cyan
        Write-Host ("-" * 50)
        Write-Host "端口`t进程名`t`tPID`t状态" -ForegroundColor White
        Write-Host ("-" * 50)
        foreach ($info in $portInfo) {
            $color = if ($info.Process -match "docker") { "Green" } else { "Yellow" }
            Write-Host "$($info.Port)`t$($info.Process)`t`t$($info.PID)`t$($info.State)" -ForegroundColor $color
        }
        Write-Host ("-" * 50)
        
        $nonDockerPorts = $portInfo | Where-Object { $_.Process -notmatch "docker" }
        if ($nonDockerPorts) {
            Write-Host "`n⚠️ 发现非Docker进程占用端口:" -ForegroundColor Yellow
            foreach ($port in $nonDockerPorts) {
                Write-Host "  端口 $($port.Port) 被 $($port.Process) (PID: $($port.PID)) 占用" -ForegroundColor Yellow
            }
            
            $response = Read-Host "`n是否要尝试停止这些进程? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                foreach ($port in $nonDockerPorts) {
                    try {
                        Write-Host "正在停止进程 $($port.Process) (PID: $($port.PID))..." -ForegroundColor Yellow
                        Stop-Process -Id $port.PID -Force
                        Write-Host "✅ 进程已停止" -ForegroundColor Green
                    } catch {
                        Write-Host "❌ 无法停止进程: $_" -ForegroundColor Red
                    }
                }
            }
        }
    }
}

# 检查Docker状态
function Check-DockerStatus {
    Write-Host "`n🔍 检查Docker状态..." -ForegroundColor Yellow
    
    try {
        # 检查Docker是否运行
        $dockerInfo = docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker运行正常" -ForegroundColor Green
            
            # 显示Docker版本信息
            $dockerVersion = docker --version
            Write-Host "版本: $dockerVersion" -ForegroundColor Gray
            
            # 显示Docker资源使用情况
            Write-Host "`n📊 Docker资源使用情况:" -ForegroundColor Cyan
            $dockerStats = docker system df 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host $dockerStats -ForegroundColor Gray
            }
            
            # 检查Docker Compose
            $composeVersion = docker-compose --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n✅ Docker Compose可用: $composeVersion" -ForegroundColor Green
            } else {
                Write-Host "`n❌ Docker Compose不可用" -ForegroundColor Red
            }
            
        } else {
            Write-Host "❌ Docker未运行或无法访问" -ForegroundColor Red
            Write-Host "错误信息: $dockerInfo" -ForegroundColor Yellow
            
            Write-Host "`n🔧 建议的解决方案:" -ForegroundColor Cyan
            Write-Host "  1. 启动Docker Desktop" -ForegroundColor White
            Write-Host "  2. 检查Docker服务状态" -ForegroundColor White
            Write-Host "  3. 重启Docker服务" -ForegroundColor White
        }
        
    } catch {
        Write-Host "❌ 无法执行Docker命令: $_" -ForegroundColor Red
        Write-Host "`n请确保Docker已正确安装并添加到PATH环境变量中" -ForegroundColor Yellow
    }
}

# 查看容器日志
function View-ContainerLogs {
    Write-Host "`n📋 查看容器日志..." -ForegroundColor Yellow
    
    $containers = @("jupyter-notebook", "spark-master", "spark-worker-1", "spark-worker-2")
    
    Write-Host "可用容器:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $containers.Count; $i++) {
        Write-Host "$($i + 1). $($containers[$i])" -ForegroundColor White
    }
    Write-Host "0. 查看所有容器日志" -ForegroundColor Gray
    
    $choice = Read-Host "`n请选择要查看日志的容器 (0-$($containers.Count))"
    
    if ($choice -eq "0") {
        Write-Host "`n📋 所有容器日志:" -ForegroundColor Cyan
        docker-compose logs --tail=50
    } elseif ($choice -ge 1 -and $choice -le $containers.Count) {
        $selectedContainer = $containers[$choice - 1]
        Write-Host "`n📋 $selectedContainer 日志:" -ForegroundColor Cyan
        docker logs --tail=50 $selectedContainer
    } else {
        Write-Host "❌ 无效选择" -ForegroundColor Red
    }
}

# 网络连接测试
function Test-NetworkConnections {
    Write-Host "`n🔍 测试网络连接..." -ForegroundColor Yellow
    
    $services = @(
        @{Name="Jupyter Notebook"; Url="http://localhost:8888"},
        @{Name="Spark Master UI"; Url="http://localhost:8080"},
        @{Name="Spark Worker 1 UI"; Url="http://localhost:8081"},
        @{Name="Spark Worker 2 UI"; Url="http://localhost:8082"}
    )
    
    foreach ($service in $services) {
        try {
            Write-Host "测试 $($service.Name)..." -ForegroundColor Gray
            $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ $($service.Name) 可访问" -ForegroundColor Green
            } else {
                Write-Host "⚠️ $($service.Name) 返回状态码: $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "❌ $($service.Name) 无法访问: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 重置环境
function Reset-Environment {
    Write-Host "`n🔄 重置环境..." -ForegroundColor Yellow
    
    $confirmation = Read-Host "这将停止所有容器并重新启动，是否继续? (y/N)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        try {
            Set-Location $projectRoot
            
            Write-Host "停止现有容器..." -ForegroundColor Gray
            docker-compose down
            
            Write-Host "启动环境..." -ForegroundColor Gray
            & "$projectRoot\scripts\quick_start.ps1"
            
            Write-Host "✅ 环境重置完成" -ForegroundColor Green
        } catch {
            Write-Host "❌ 重置失败: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "操作已取消" -ForegroundColor Gray
    }
}

# 完全清理
function Clean-All {
    Write-Host "`n🧹 完全清理..." -ForegroundColor Yellow
    
    Write-Host "⚠️ 警告: 这将删除所有Docker容器、镜像和卷!" -ForegroundColor Red
    $confirmation = Read-Host "是否确定要继续? (输入 'YES' 确认)"
    
    if ($confirmation -eq 'YES') {
        try {
            Set-Location $projectRoot
            
            Write-Host "停止所有容器..." -ForegroundColor Gray
            docker-compose down -v
            
            Write-Host "删除相关镜像..." -ForegroundColor Gray
            docker rmi $(docker images -q --filter "reference=*spark*") -f 2>&1 | Out-Null
            docker rmi $(docker images -q --filter "reference=*jupyter*") -f 2>&1 | Out-Null
            
            Write-Host "清理Docker系统..." -ForegroundColor Gray
            docker system prune -af
            
            Write-Host "✅ 完全清理完成" -ForegroundColor Green
            Write-Host "现在可以运行 'scripts\quick_start.ps1' 重新开始" -ForegroundColor White
            
        } catch {
            Write-Host "❌ 清理失败: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "操作已取消" -ForegroundColor Gray
    }
}

# 显示常见问题
function Show-CommonIssues {
    Write-Host "`n📚 常见问题和解决方案:" -ForegroundColor Cyan
    
    foreach ($key in $commonIssues.Keys) {
        $issue = $commonIssues[$key]
        Write-Host "`n🔸 $($issue.Name)" -ForegroundColor Yellow
        Write-Host "   问题描述: $($issue.Description)" -ForegroundColor Gray
        Write-Host "   解决方案:" -ForegroundColor White
        foreach ($solution in $issue.Solutions) {
            Write-Host "     • $solution" -ForegroundColor Gray
        }
    }
}

# 主程序逻辑
if ($Auto) {
    Start-AutoDiagnosis
} elseif ($Reset) {
    Reset-Environment
} elseif ($CleanAll) {
    Clean-All
} elseif ($Issue) {
    if ($commonIssues.ContainsKey($Issue.ToLower())) {
        $selectedIssue = $commonIssues[$Issue.ToLower()]
        Write-Host "`n🔸 $($selectedIssue.Name)" -ForegroundColor Yellow
        Write-Host "问题描述: $($selectedIssue.Description)" -ForegroundColor Gray
        Write-Host "`n解决方案:" -ForegroundColor White
        foreach ($solution in $selectedIssue.Solutions) {
            Write-Host "  • $solution" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ 未知问题类型: $Issue" -ForegroundColor Red
        Write-Host "可用的问题类型: $($commonIssues.Keys -join ', ')" -ForegroundColor Gray
    }
} else {
    # 交互式菜单
    do {
        Show-TroubleshootMenu
        $choice = Read-Host "请选择操作 (0-8)"
        
        switch ($choice) {
            "1" { Start-AutoDiagnosis }
            "2" { Check-PortUsage }
            "3" { Check-DockerStatus }
            "4" { View-ContainerLogs }
            "5" { Test-NetworkConnections }
            "6" { Reset-Environment }
            "7" { Clean-All }
            "8" { Show-CommonIssues }
            "0" { 
                Write-Host "退出故障排除工具" -ForegroundColor Gray
                break 
            }
            default { 
                Write-Host "❌ 无效选择，请重试" -ForegroundColor Red 
            }
        }
        
        if ($choice -ne "0") {
            Write-Host "`n按任意键继续..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
    } while ($choice -ne "0")
}

Write-Host "`n故障排除完成!" -ForegroundColor Cyan