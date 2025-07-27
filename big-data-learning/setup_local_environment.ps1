# 本地大数据学习环境设置脚本

# 添加参数支持选择pip镜像源
param(
    [string]$Mirror = "tsinghua"  # 默认使用清华镜像源
)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    设置本地大数据学习环境" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# 检查Python是否安装
Write-Host "`n检查Python环境..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ 找到Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ 未找到Python，请先安装Python 3.8+" -ForegroundColor Red
    Write-Host "下载地址: https://www.python.org/downloads/" -ForegroundColor Gray
    exit 1
}

# 检查pip是否可用
Write-Host "`n检查pip..." -ForegroundColor Yellow
try {
    $pipVersion = pip --version 2>&1
    Write-Host "✓ 找到pip: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ 未找到pip" -ForegroundColor Red
    exit 1
}

# 根据参数设置pip镜像源
Write-Host "`n配置pip镜像源..." -ForegroundColor Yellow
$mirrorUrl = ""
$trustedHost = ""

switch ($Mirror) {
    "tsinghua" {
        $mirrorUrl = "https://pypi.tuna.tsinghua.edu.cn/simple"
        $trustedHost = "pypi.tuna.tsinghua.edu.cn"
        Write-Host "使用清华大学镜像源" -ForegroundColor Green
    }
    "aliyun" {
        $mirrorUrl = "https://mirrors.aliyun.com/pypi/simple/"
        $trustedHost = "mirrors.aliyun.com"
        Write-Host "使用阿里云镜像源" -ForegroundColor Green
    }
    "douban" {
        $mirrorUrl = "https://pypi.douban.com/simple/"
        $trustedHost = "pypi.douban.com"
        Write-Host "使用豆瓣镜像源" -ForegroundColor Green
    }
    "default" {
        Write-Host "使用默认PyPI源" -ForegroundColor Yellow
    }
    default {
        $mirrorUrl = "https://pypi.tuna.tsinghua.edu.cn/simple"
        $trustedHost = "pypi.tuna.tsinghua.edu.cn"
        Write-Host "使用清华大学镜像源（默认）" -ForegroundColor Green
    }
}

# 配置pip镜像源
if ($Mirror -ne "default") {
    $pipConf = @"
[global]
index-url = $mirrorUrl
trusted-host = $trustedHost
timeout = 120
"@
    
    if ($IsWindows) {
        $pipDir = "$env:APPDATA\pip"
        if (!(Test-Path $pipDir)) {
            New-Item -ItemType Directory -Path $pipDir | Out-Null
        }
        $pipConf | Out-File -FilePath "$pipDir\pip.ini" -Encoding UTF8
    } else {
        $homeDir = [Environment]::GetFolderPath("UserProfile")
        if (!$homeDir) { $homeDir = $env:HOME }
        $pipDir = "$homeDir/.pip"
        if (!(Test-Path $pipDir)) {
            New-Item -ItemType Directory -Path $pipDir | Out-Null
        }
        $pipConf | Out-File -FilePath "$pipDir/pip.conf" -Encoding UTF8
    }
    Write-Host "✓ pip镜像源配置完成" -ForegroundColor Green
}

# 创建虚拟环境
Write-Host "`n创建Python虚拟环境..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "虚拟环境已存在，跳过创建" -ForegroundColor Gray
} else {
    python -m venv venv
    Write-Host "✓ 虚拟环境创建成功" -ForegroundColor Green
}

# 激活虚拟环境
Write-Host "`n激活虚拟环境..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

# 升级pip
Write-Host "`n升级pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# 安装必要的包
Write-Host "`n安装Python包..." -ForegroundColor Yellow
$packages = @(
    "pyspark==3.4.0",
    "jupyter",
    "jupyterlab", 
    "pandas",
    "numpy",
    "matplotlib",
    "seaborn",
    "plotly",
    "findspark"
)

foreach ($package in $packages) {
    Write-Host "安装 $package..." -ForegroundColor Gray
    pip install $package
}

Write-Host "✓ 所有包安装完成" -ForegroundColor Green

# 创建启动脚本
Write-Host "`n创建启动脚本..." -ForegroundColor Yellow

$startScript = @"
# 启动本地Spark学习环境
Write-Host "启动本地Spark学习环境..." -ForegroundColor Cyan

# 激活虚拟环境
& ".\venv\Scripts\Activate.ps1"

# 设置环境变量
`$env:PYSPARK_DRIVER_PYTHON = "jupyter"
`$env:PYSPARK_DRIVER_PYTHON_OPTS = "lab --no-browser --port=8888 --ip=0.0.0.0 --allow-root"
`$env:PYSPARK_PYTHON = "python"

# 启动Jupyter Lab
Write-Host "正在启动Jupyter Lab..." -ForegroundColor Yellow
Write-Host "访问地址: http://localhost:8888" -ForegroundColor Cyan

jupyter lab --no-browser --port=8888 --ip=0.0.0.0 --allow-root
"@

$startScript | Out-File -FilePath "start_local_environment.ps1" -Encoding UTF8

Write-Host "✓ 启动脚本创建完成: start_local_environment.ps1" -ForegroundColor Green

# 创建Spark配置文件
Write-Host "`n创建Spark配置..." -ForegroundColor Yellow

$sparkConfig = @"
import findspark
import os
from pyspark.sql import SparkSession
from pyspark import SparkContext, SparkConf

# 初始化findspark
findspark.init()

def create_spark_session(app_name="BigDataLearning"):
    '''创建Spark会话'''
    conf = SparkConf()
    conf.setAppName(app_name)
    conf.setMaster("local[*]")  # 使用所有可用核心
    conf.set("spark.sql.adaptive.enabled", "true")
    conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
    conf.set("spark.driver.memory", "2g")
    conf.set("spark.executor.memory", "2g")
    
    spark = SparkSession.builder.config(conf=conf).getOrCreate()
    spark.sparkContext.setLogLevel("WARN")  # 减少日志输出
    
    print(f"Spark版本: {spark.version}")
    print(f"Spark UI: http://localhost:4040")
    
    return spark

# 自动创建spark会话
spark = create_spark_session()
sc = spark.sparkContext

print("Spark环境已准备就绪!")
print("使用 'spark' 变量访问SparkSession")
print("使用 'sc' 变量访问SparkContext")
"@

$sparkConfig | Out-File -FilePath "notebooks/spark_init.py" -Encoding UTF8

Write-Host "✓ Spark配置文件创建完成: notebooks/spark_init.py" -ForegroundColor Green

Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "    本地环境设置完成!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan

Write-Host "`n使用方法:" -ForegroundColor White
Write-Host "1. 运行启动脚本: .\start_local_environment.ps1" -ForegroundColor Cyan
Write-Host "2. 在Jupyter中导入: exec(open('spark_init.py').read())" -ForegroundColor Cyan
Write-Host "3. 开始学习Spark!" -ForegroundColor Cyan

Write-Host "`n注意事项:" -ForegroundColor Yellow
Write-Host "• 本地模式使用所有CPU核心" -ForegroundColor Gray
Write-Host "• Spark UI地址: http://localhost:4040" -ForegroundColor Gray
Write-Host "• 数据文件放在 ./data 目录" -ForegroundColor Gray