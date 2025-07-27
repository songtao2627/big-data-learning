#!/usr/bin/env pwsh
# 测试 runcode 插件配置

Write-Host "✅ PowerShell 脚本运行成功！" -ForegroundColor Green
Write-Host "当前时间: $(Get-Date)" -ForegroundColor Yellow
Write-Host "当前目录: $(Get-Location)" -ForegroundColor Cyan
Write-Host "PowerShell 版本: $($PSVersionTable.PSVersion)" -ForegroundColor Magenta

# 测试基本命令
Get-ChildItem -Path . -Name "*.ps1" | ForEach-Object {
    Write-Host "发现 PowerShell 脚本: $_" -ForegroundColor Blue
}

Write-Host "🎉 测试完成！" -ForegroundColor Green