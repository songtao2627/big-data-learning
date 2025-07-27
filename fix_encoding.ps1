#!/usr/bin/env pwsh
# 修复 PowerShell 编码问题

Write-Host "🔧 修复 PowerShell 编码设置..." -ForegroundColor Yellow

# 设置控制台编码为 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "✅ 编码设置完成！" -ForegroundColor Green
Write-Host "当前控制台编码: $([Console]::OutputEncoding.EncodingName)" -ForegroundColor Cyan
Write-Host "当前输出编码: $($OutputEncoding.EncodingName)" -ForegroundColor Cyan

# 测试中文显示
Write-Host "🚀 测试中文显示: 大数据学习平台" -ForegroundColor Magenta
Write-Host "📊 Spark 集群状态检查" -ForegroundColor Blue
Write-Host "🐳 Docker 容器管理" -ForegroundColor Green