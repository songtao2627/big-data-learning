# 大数据学习平台环境验证脚本
# 用于验证环境是否正确配置并能正常工作

param(
    [switch]$Detailed,
    [switch]$SkipSpark,
    [switch]$SkipJupyter
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    大数据学习平台环境验证" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

$testResults = @()
$overallSuccess = $true

# 辅助函数：添加测试结果
function Add-TestResult {
    param($Name, $Status, $Message, $Details = "")
    
    $result = @{
        Name = $Name
        Status = $Status
        Message = $Message
        Details = $Details
    }
    
    $script:testResults += $result
    
    if ($Status -eq "PASS") {
        Write-Host "✅ $Name" -ForegroundColor Green
        if ($Message) { Write-Host "   $Message" -ForegroundColor Gray }
    } elseif ($Status -eq "WARN") {
        Write-Host "⚠️ $Name" -ForegroundColor Yellow
        if ($Message) { Write-Host "   $Message" -ForegroundColor Yellow }
    } else {
        Write-Host "❌ $Name" -ForegroundColor Red
        if ($Message) { Write-Host "   $Message" -ForegroundColor Red }
        $script:overallSuccess = $false
    }
    
    if ($Detailed -and $Details) {
        Write-Host "   详细信息: $Details" -ForegroundColor Gray
    }
}

# 测试1: Docker状态检查
Write-Host "`n🔍 检查Docker状态..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        $dockerVersion = docker --version
        Add-TestResult "Docker状态检查" "PASS" "Docker运行正常" $dockerVersion
    } else {
        Add-TestResult "Docker状态检查" "FAIL" "Docker未运行或无法访问"
    }
} catch {
    Add-TestResult "Docker状态检查" "FAIL" "无法执行Docker命令: $_"
}

# 测试2: 容器状态检查
Write-Host "`n🔍 检查容器状态..." -ForegroundColor Yellow
$requiredContainers = @(
    @{Name="jupyter-notebook"; Description="Jupyter Notebook"},
    @{Name="spark-master"; Description="Spark Master"},
    @{Name="spark-worker-1"; Description="Spark Worker 1"},
    @{Name="spark-worker-2"; Description="Spark Worker 2"}
)

foreach ($container in $requiredContainers) {
    try {
        $status = docker ps -f "name=$($container.Name)" --format "{{.Status}}" 2>&1
        if ($status -match "Up") {
            $uptime = docker ps -f "name=$($container.Name)" --format "{{.Status}}" | ForEach-Object { $_ -replace "Up ", "" }
            Add-TestResult "$($container.Description)容器" "PASS" "运行中 ($uptime)"
        } else {
            Add-TestResult "$($container.Description)容器" "FAIL" "未运行"
        }
    } catch {
        Add-TestResult "$($container.Description)容器" "FAIL" "检查失败: $_"
    }
}

# 测试3: 网络连接检查
Write-Host "`n🔍 检查服务网络连接..." -ForegroundColor Yellow
$services = @(
    @{Name="Jupyter Notebook"; Url="http://localhost:8888"; ExpectedStatus=200},
    @{Name="Spark Master UI"; Url="http://localhost:8080"; ExpectedStatus=200},
    @{Name="Spark Worker 1 UI"; Url="http://localhost:8081"; ExpectedStatus=200},
    @{Name="Spark Worker 2 UI"; Url="http://localhost:8082"; ExpectedStatus=200}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq $service.ExpectedStatus) {
            Add-TestResult "$($service.Name)网络连接" "PASS" "可访问 ($($service.Url))"
        } else {
            Add-TestResult "$($service.Name)网络连接" "WARN" "返回状态码: $($response.StatusCode)"
        }
    } catch {
        Add-TestResult "$($service.Name)网络连接" "FAIL" "无法访问 $($service.Url)"
    }
}

# 测试4: Spark集群连接测试
if (-not $SkipSpark) {
    Write-Host "`n🔍 测试Spark集群连接..." -ForegroundColor Yellow
    try {
        # 创建临时Python脚本来测试Spark连接
        $sparkTestScript = @"
import sys
import os
sys.path.append('/opt/spark/python')
sys.path.append('/opt/spark/python/lib/py4j-0.10.9.7-src.zip')

try:
    from pyspark.sql import SparkSession
    
    # 创建SparkSession
    spark = SparkSession.builder \
        .appName("EnvironmentTest") \
        .master("spark://spark-master:7077") \
        .config("spark.executor.memory", "1g") \
        .config("spark.driver.memory", "1g") \
        .getOrCreate()
    
    # 测试基本操作
    data = range(1, 101)
    rdd = spark.sparkContext.parallelize(data)
    result = rdd.map(lambda x: x * 2).filter(lambda x: x > 100).count()
    
    print(f"SUCCESS: Spark test completed. Result count: {result}")
    print(f"Spark version: {spark.version}")
    print(f"Master: {spark.sparkContext.master}")
    
    spark.stop()
    
except Exception as e:
    print(f"ERROR: {str(e)}")
    sys.exit(1)
"@
        
        # 将脚本写入临时文件
        $tempScript = Join-Path $env:TEMP "spark_test.py"
        $sparkTestScript | Out-File -FilePath $tempScript -Encoding utf8
        
        # 在Jupyter容器中执行测试
        $testOutput = docker exec jupyter-notebook python /tmp/spark_test.py 2>&1
        
        # 将脚本复制到容器中并执行
        docker cp $tempScript jupyter-notebook:/tmp/spark_test.py 2>&1 | Out-Null
        $testOutput = docker exec jupyter-notebook python /tmp/spark_test.py 2>&1
        
        if ($testOutput -match "SUCCESS") {
            $sparkVersion = ($testOutput | Select-String -Pattern "Spark version: (.+)").Matches[0].Groups[1].Value
            Add-TestResult "Spark集群连接" "PASS" "连接成功，版本: $sparkVersion"
        } else {
            Add-TestResult "Spark集群连接" "FAIL" "连接失败: $testOutput"
        }
        
        # 清理临时文件
        Remove-Item $tempScript -ErrorAction SilentlyContinue
        
    } catch {
        Add-TestResult "Spark集群连接" "FAIL" "测试执行失败: $_"
    }
}

# 测试5: Jupyter Notebook功能测试
if (-not $SkipJupyter) {
    Write-Host "`n🔍 测试Jupyter Notebook功能..." -ForegroundColor Yellow
    try {
        # 检查Jupyter是否可以执行Python代码
        $jupyterTestScript = @"
import sys
import json

# 测试基本Python功能
try:
    result = {
        'python_version': sys.version,
        'test_calculation': sum(range(1, 11)),
        'status': 'success'
    }
    print(json.dumps(result))
except Exception as e:
    error_result = {
        'error': str(e),
        'status': 'error'
    }
    print(json.dumps(error_result))
"@
        
        # 将脚本写入临时文件并在容器中执行
        $tempScript = Join-Path $env:TEMP "jupyter_test.py"
        $jupyterTestScript | Out-File -FilePath $tempScript -Encoding utf8
        
        docker cp $tempScript jupyter-notebook:/tmp/jupyter_test.py 2>&1 | Out-Null
        $testOutput = docker exec jupyter-notebook python /tmp/jupyter_test.py 2>&1
        
        if ($testOutput -match '"status": "success"') {
            $testData = $testOutput | ConvertFrom-Json
            Add-TestResult "Jupyter Python环境" "PASS" "Python环境正常"
        } else {
            Add-TestResult "Jupyter Python环境" "FAIL" "Python环境异常: $testOutput"
        }
        
        # 清理临时文件
        Remove-Item $tempScript -ErrorAction SilentlyContinue
        
    } catch {
        Add-TestResult "Jupyter Python环境" "FAIL" "测试执行失败: $_"
    }
}

# 测试6: 数据文件检查
Write-Host "`n🔍 检查示例数据文件..." -ForegroundColor Yellow
$dataFiles = @(
    @{Path="data/sample/sales_data.csv"; Description="销售数据CSV文件"},
    @{Path="data/sample/user_behavior.json"; Description="用户行为JSON文件"},
    @{Path="data/sample/server_logs.txt"; Description="服务器日志文件"}
)

foreach ($file in $dataFiles) {
    $fullPath = Join-Path $projectRoot $file.Path
    if (Test-Path $fullPath) {
        $fileSize = (Get-Item $fullPath).Length
        Add-TestResult "$($file.Description)" "PASS" "文件存在 (大小: $fileSize 字节)"
    } else {
        Add-TestResult "$($file.Description)" "WARN" "文件不存在: $($file.Path)"
    }
}

# 测试7: 学习笔记本检查
Write-Host "`n🔍 检查学习笔记本..." -ForegroundColor Yellow
$notebooks = @(
    @{Path="notebooks/00-welcome.ipynb"; Description="欢迎笔记本"},
    @{Path="notebooks/01-spark-basics/rdd-fundamentals.ipynb"; Description="RDD基础笔记本"},
    @{Path="notebooks/01-spark-basics/dataframe-operations.ipynb"; Description="DataFrame操作笔记本"},
    @{Path="notebooks/02-spark-sql/sql-basics.ipynb"; Description="SQL基础笔记本"}
)

foreach ($notebook in $notebooks) {
    $fullPath = Join-Path $projectRoot $notebook.Path
    if (Test-Path $fullPath) {
        Add-TestResult "$($notebook.Description)" "PASS" "笔记本存在"
    } else {
        Add-TestResult "$($notebook.Description)" "WARN" "笔记本不存在: $($notebook.Path)"
    }
}

# 显示测试结果摘要
Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "    验证结果摘要" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$warnCount = ($testResults | Where-Object { $_.Status -eq "WARN" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $testResults.Count

Write-Host "`n📊 测试统计:" -ForegroundColor White
Write-Host "  ✅ 通过: $passCount" -ForegroundColor Green
Write-Host "  ⚠️ 警告: $warnCount" -ForegroundColor Yellow
Write-Host "  ❌ 失败: $failCount" -ForegroundColor Red
Write-Host "  📝 总计: $totalCount" -ForegroundColor Gray

if ($overallSuccess) {
    Write-Host "`n🎉 环境验证通过!" -ForegroundColor Green
    Write-Host "您的大数据学习平台已准备就绪" -ForegroundColor White
    
    if ($warnCount -gt 0) {
        Write-Host "`n⚠️ 注意事项:" -ForegroundColor Yellow
        $testResults | Where-Object { $_.Status -eq "WARN" } | ForEach-Object {
            Write-Host "  • $($_.Name): $($_.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n🚀 建议的下一步:" -ForegroundColor Cyan
    Write-Host "  1. 在浏览器中打开 http://localhost:8888" -ForegroundColor White
    Write-Host "  2. 从 '00-welcome.ipynb' 开始学习" -ForegroundColor White
    Write-Host "  3. 按照学习路径逐步进行" -ForegroundColor White
    
} else {
    Write-Host "`n❌ 环境验证失败!" -ForegroundColor Red
    Write-Host "请解决以下问题后重新验证:" -ForegroundColor Yellow
    
    $testResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n🔧 建议的解决方案:" -ForegroundColor Cyan
    Write-Host "  1. 重启Docker Desktop" -ForegroundColor White
    Write-Host "  2. 运行 'scripts\quick_start.ps1 -Reset' 重置环境" -ForegroundColor White
    Write-Host "  3. 检查端口占用情况" -ForegroundColor White
    Write-Host "  4. 查看容器日志: docker-compose logs" -ForegroundColor White
    
    exit 1
}

# 如果启用详细模式，显示所有测试结果
if ($Detailed) {
    Write-Host "`n📋 详细测试结果:" -ForegroundColor Cyan
    Write-Host "-" * 60
    foreach ($result in $testResults) {
        $statusIcon = switch ($result.Status) {
            "PASS" { "✅" }
            "WARN" { "⚠️" }
            "FAIL" { "❌" }
        }
        Write-Host "$statusIcon $($result.Name)" -ForegroundColor White
        Write-Host "   状态: $($result.Status)" -ForegroundColor Gray
        if ($result.Message) {
            Write-Host "   信息: $($result.Message)" -ForegroundColor Gray
        }
        if ($result.Details) {
            Write-Host "   详细: $($result.Details)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

Write-Host "验证完成!" -ForegroundColor Cyan