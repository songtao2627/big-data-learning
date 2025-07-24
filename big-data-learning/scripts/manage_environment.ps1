# 大数据学习平台环境管理脚本
# 统一的环境管理入口

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "status", "verify", "troubleshoot", "clean", "help")]
    [string]$Action = "help",
    
    [switch]$Full,
    [switch]$Reset,
    [switch]$Force,
    [switch]$Detailed,
    [switch]$Auto
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# 显示帮助信息
function Show-Help {
    Write-Host "大数据学习平台环境管理工具" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "用法: .\manage_environment.ps1 <action> [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "可用操作:" -ForegroundColor Yellow
    Write-Host "  start        启动环境" -ForegroundColor White
    Write-Host "  stop         停止环境" -ForegroundColor White
    Write-Host "  restart      重启环境" -ForegroundColor White
    Write-Host "  status       检查环境状态" -ForegroundColor White
    Write-Host "  verify       验证环境配置" -ForegroundColor White
    Write-Host "  troubleshoot 故障排除" -ForegroundColor White
    Write-Host "  clean        清理环境" -ForegroundColor White
    Write-Host "  help         显示帮助信息" -ForegroundColor White
    Write-Host ""
    Write-Host "可用选项:" -ForegroundColor Yellow
    Write-Host "  -Full        启动完整环境 (包含Kafka, Elasticsearch等)" -ForegroundColor Gray
    Write-Host "  -Reset       重置环境" -ForegroundColor Gray
    Write-Host "  -Force       强制执行操作" -ForegroundColor Gray
    Write-Host "  -Detailed    显示详细信息" -ForegroundColor Gray
    Write-Host "  -Auto        自动模式" -ForegroundColor Gray
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Yellow
    Write-Host "  .\manage_environment.ps1 start           # 启动基础环境" -ForegroundColor Gray
    Write-Host "  .\manage_environment.ps1 start -Full     # 启动完整环境" -ForegroundColor Gray
    Write-Host "  .\manage_environment.ps1 restart -Reset  # 重置并重启环境" -ForegroundColor Gray
    Write-Host "  .\manage_environment.ps1 status -Detailed # 详细状态检查" -ForegroundColor Gray
    Write-Host "  .\manage_environment.ps1 troubleshoot -Auto # 自动故障排除" -ForegroundColor Gray
    Write-Host ""
    Write-Host "快速开始:" -ForegroundColor Green
    Write-Host "  对于初学者，推荐使用: .\manage_environment.ps1 start" -ForegroundColor White
    Write-Host ""
}

# 启动环境
function Start-Environment {
    Write-Host "🚀 启动大数据学习环境..." -ForegroundColor Cyan
    
    $startArgs = @()
    if ($Full) { $startArgs += "-All" }
    if ($Force) { $startArgs += "-Force" }
    
    try {
        & "$projectRoot\scripts\start_environment.ps1" @startArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ 环境启动成功!" -ForegroundColor Green
            
            # 自动运行健康检查
            Write-Host "`n正在进行健康检查..." -ForegroundColor Yellow
            & "$projectRoot\scripts\health_check.ps1" -Quick
            
        } else {
            Write-Host "`n❌ 环境启动失败" -ForegroundColor Red
            Write-Host "运行 '.\manage_environment.ps1 troubleshoot' 获取帮助" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "`n❌ 启动过程中出现错误: $_" -ForegroundColor Red
    }
}

# 停止环境
function Stop-Environment {
    Write-Host "🛑 停止大数据学习环境..." -ForegroundColor Yellow
    
    try {
        Set-Location $projectRoot
        
        if ($Force) {
            Write-Host "强制停止所有容器..." -ForegroundColor Gray
            docker-compose down -v
        } else {
            Write-Host "正常停止容器..." -ForegroundColor Gray
            docker-compose down
        }
        
        Write-Host "✅ 环境已停止" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ 停止环境时出现错误: $_" -ForegroundColor Red
    }
}

# 重启环境
function Restart-Environment {
    Write-Host "🔄 重启大数据学习环境..." -ForegroundColor Cyan
    
    # 先停止
    Stop-Environment
    
    # 等待一下
    Write-Host "等待容器完全停止..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    
    # 再启动
    Start-Environment
}

# 检查状态
function Check-Status {
    Write-Host "📊 检查环境状态..." -ForegroundColor Cyan
    
    $statusArgs = @()
    if ($Detailed) { $statusArgs += "-Detailed" }
    if ($Full) { 
        $statusArgs += "-Streaming"
        $statusArgs += "-Analytics"
    }
    
    & "$projectRoot\scripts\health_check.ps1" @statusArgs
}

# 验证环境
function Verify-Environment {
    Write-Host "🔍 验证环境配置..." -ForegroundColor Cyan
    
    $verifyArgs = @()
    if ($Detailed) { $verifyArgs += "-Detailed" }
    
    & "$projectRoot\scripts\verify_environment.ps1" @verifyArgs
}

# 故障排除
function Start-Troubleshooting {
    Write-Host "🔧 启动故障排除..." -ForegroundColor Cyan
    
    $troubleshootArgs = @()
    if ($Auto) { $troubleshootArgs += "-Auto" }
    if ($Reset) { $troubleshootArgs += "-Reset" }
    
    & "$projectRoot\scripts\troubleshoot.ps1" @troubleshootArgs
}

# 清理环境
function Clean-Environment {
    Write-Host "🧹 清理环境..." -ForegroundColor Yellow
    
    $confirmation = Read-Host "这将删除所有容器和数据，是否继续? (y/N)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        & "$projectRoot\scripts\troubleshoot.ps1" -CleanAll
    } else {
        Write-Host "操作已取消" -ForegroundColor Gray
    }
}

# 显示环境信息
function Show-EnvironmentInfo {
    Write-Host "大数据学习平台环境信息" -ForegroundColor Cyan
    Write-Host "=" * 40 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "项目目录: $projectRoot" -ForegroundColor Gray
    Write-Host "当前时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    # 检查Docker状态
    try {
        $dockerVersion = docker --version
        Write-Host "Docker版本: $dockerVersion" -ForegroundColor White
        
        $composeVersion = docker-compose --version
        Write-Host "Docker Compose版本: $composeVersion" -ForegroundColor White
    } catch {
        Write-Host "Docker状态: 未安装或不可用" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "可用脚本:" -ForegroundColor Yellow
    $scripts = Get-ChildItem "$projectRoot\scripts\*.ps1" | Select-Object Name
    foreach ($script in $scripts) {
        Write-Host "  • $($script.Name)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "学习资源:" -ForegroundColor Yellow
    Write-Host "  • 笔记本目录: notebooks/" -ForegroundColor Gray
    Write-Host "  • 示例数据: data/sample/" -ForegroundColor Gray
    Write-Host "  • 学习路径: notebooks/learning_path.md" -ForegroundColor Gray
    Write-Host "  • 调试指南: notebooks/debugging-guide.md" -ForegroundColor Gray
}

# 主程序逻辑
Write-Host "大数据学习平台环境管理工具" -ForegroundColor Cyan
Write-Host "当前操作: $Action" -ForegroundColor Gray
Write-Host ""

switch ($Action.ToLower()) {
    "start" {
        Start-Environment
    }
    "stop" {
        Stop-Environment
    }
    "restart" {
        Restart-Environment
    }
    "status" {
        Check-Status
    }
    "verify" {
        Verify-Environment
    }
    "troubleshoot" {
        Start-Troubleshooting
    }
    "clean" {
        Clean-Environment
    }
    "info" {
        Show-EnvironmentInfo
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "❌ 未知操作: $Action" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}

Write-Host "`n操作完成!" -ForegroundColor Green