# Spark集群状态检查脚本

param(
    [switch]$Detailed
)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    Spark集群状态检查" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# 检查Spark Master状态
Write-Host "`n检查Spark Master状态..." -ForegroundColor Yellow

try {
    $masterResponse = Invoke-RestMethod -Uri "http://localhost:8080/json" -TimeoutSec 10
    
    Write-Host "✓ Spark Master 正在运行" -ForegroundColor Green
    Write-Host "  版本: $($masterResponse.version)" -ForegroundColor White
    Write-Host "  状态: $($masterResponse.status)" -ForegroundColor White
    Write-Host "  URL: $($masterResponse.url)" -ForegroundColor White
    Write-Host "  活跃Worker数: $($masterResponse.aliveworkers)" -ForegroundColor White
    Write-Host "  总核心数: $($masterResponse.cores)" -ForegroundColor White
    Write-Host "  已使用核心数: $($masterResponse.coresused)" -ForegroundColor White
    Write-Host "  总内存: $($masterResponse.memory)" -ForegroundColor White
    Write-Host "  已使用内存: $($masterResponse.memoryused)" -ForegroundColor White
    
    if ($Detailed -and $masterResponse.workers) {
        Write-Host "`n  Worker详细信息:" -ForegroundColor Cyan
        foreach ($worker in $masterResponse.workers) {
            Write-Host "    Worker ID: $($worker.id)" -ForegroundColor White
            Write-Host "    主机: $($worker.host):$($worker.port)" -ForegroundColor White
            Write-Host "    状态: $($worker.state)" -ForegroundColor White
            Write-Host "    核心数: $($worker.cores) (已使用: $($worker.coresused))" -ForegroundColor White
            Write-Host "    内存: $($worker.memory) (已使用: $($worker.memoryused))" -ForegroundColor White
            Write-Host "    最后心跳: $($worker.lastheartbeat)" -ForegroundColor White
            Write-Host "    ---" -ForegroundColor Gray
        }
    }
    
    if ($masterResponse.activeapps -and $masterResponse.activeapps.Count -gt 0) {
        Write-Host "`n  活跃应用:" -ForegroundColor Cyan
        foreach ($app in $masterResponse.activeapps) {
            Write-Host "    应用ID: $($app.id)" -ForegroundColor White
            Write-Host "    应用名: $($app.name)" -ForegroundColor White
            Write-Host "    开始时间: $($app.starttime)" -ForegroundColor White
            Write-Host "    使用核心数: $($app.coresgranted)" -ForegroundColor White
            Write-Host "    ---" -ForegroundColor Gray
        }
    } else {
        Write-Host "  当前没有活跃的应用" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "✗ 无法连接到Spark Master: $_" -ForegroundColor Red
    Write-Host "  请确保Spark Master容器正在运行" -ForegroundColor Yellow
}

# 检查Worker状态
Write-Host "`n检查Spark Worker状态..." -ForegroundColor Yellow

$workers = @(
    @{Name="Worker 1"; Port=8081},
    @{Name="Worker 2"; Port=8082}
)

foreach ($worker in $workers) {
    try {
        $workerResponse = Invoke-RestMethod -Uri "http://localhost:$($worker.Port)/json" -TimeoutSec 5
        
        Write-Host "✓ $($worker.Name) 正在运行" -ForegroundColor Green
        Write-Host "  Master URL: $($workerResponse.masterurl)" -ForegroundColor White
        Write-Host "  Worker URL: $($workerResponse.workerurl)" -ForegroundColor White
        Write-Host "  状态: $($workerResponse.state)" -ForegroundColor White
        Write-Host "  核心数: $($workerResponse.cores) (已使用: $($workerResponse.coresused))" -ForegroundColor White
        Write-Host "  内存: $($workerResponse.memory) (已使用: $($workerResponse.memoryused))" -ForegroundColor White
        
        if ($Detailed -and $workerResponse.executors) {
            Write-Host "    执行器数量: $($workerResponse.executors.Count)" -ForegroundColor White
            foreach ($executor in $workerResponse.executors) {
                Write-Host "      执行器ID: $($executor.id)" -ForegroundColor Gray
                Write-Host "      应用ID: $($executor.appid)" -ForegroundColor Gray
                Write-Host "      核心数: $($executor.cores)" -ForegroundColor Gray
                Write-Host "      内存: $($executor.memory)" -ForegroundColor Gray
            }
        }
        
    } catch {
        Write-Host "✗ 无法连接到$($worker.Name): $_" -ForegroundColor Red
    }
    Write-Host ""
}

# 测试Spark连接
Write-Host "测试Spark连接..." -ForegroundColor Yellow

try {
    # 创建一个简单的测试脚本
    $testScript = @"
from pyspark.sql import SparkSession
import sys

try:
    spark = SparkSession.builder \
        .appName("ClusterTest") \
        .master("spark://spark-master:7077") \
        .getOrCreate()
    
    # 创建一个简单的DataFrame测试
    data = [(1, "test1"), (2, "test2"), (3, "test3")]
    df = spark.createDataFrame(data, ["id", "value"])
    count = df.count()
    
    print(f"SUCCESS: 成功连接到Spark集群，测试数据行数: {count}")
    
    spark.stop()
    sys.exit(0)
    
except Exception as e:
    print(f"ERROR: 连接Spark集群失败: {e}")
    sys.exit(1)
"@

    # 将测试脚本写入临时文件
    $tempScript = "$env:TEMP\spark_test.py"
    $testScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    # 在Jupyter容器中执行测试
    $testResult = docker exec jupyter-notebook python $tempScript 2>&1
    
    if ($testResult -match "SUCCESS") {
        Write-Host "✓ Spark集群连接测试成功" -ForegroundColor Green
        Write-Host "  $testResult" -ForegroundColor White
    } else {
        Write-Host "✗ Spark集群连接测试失败" -ForegroundColor Red
        Write-Host "  $testResult" -ForegroundColor Yellow
    }
    
    # 清理临时文件
    Remove-Item $tempScript -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "✗ 执行Spark连接测试时出错: $_" -ForegroundColor Red
}

Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "    Spark集群检查完成" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

Write-Host "`n提示:" -ForegroundColor White
Write-Host "• 访问 http://localhost:8080 查看Spark Master UI" -ForegroundColor Gray
Write-Host "• 访问 http://localhost:8081 查看Worker 1 UI" -ForegroundColor Gray
Write-Host "• 访问 http://localhost:8082 查看Worker 2 UI" -ForegroundColor Gray
Write-Host "• 使用 -Detailed 参数获取更详细的信息" -ForegroundColor Gray