# 大数据学习平台环境初始化脚本
# 用于首次设置环境

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "正在初始化大数据学习平台环境..." -ForegroundColor Cyan
Write-Host "项目根目录: $projectRoot" -ForegroundColor Cyan

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

# 切换到项目根目录
Set-Location $projectRoot

# 创建必要的目录结构
Write-Host "`n正在创建目录结构..." -ForegroundColor Cyan

$directories = @(
    "data",
    "data/sample",
    "data/medium",
    "data/large",
    "notebooks",
    "notebooks/01-spark-basics",
    "notebooks/02-spark-sql",
    "notebooks/03-spark-streaming",
    "notebooks/04-projects",
    "notebooks/05-flink"
)

foreach ($dir in $directories) {
    $path = Join-Path -Path $projectRoot -ChildPath $dir
    if (-not (Test-Path -Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "  创建目录: $dir" -ForegroundColor White
    } else {
        Write-Host "  目录已存在: $dir" -ForegroundColor Gray
    }
}

# 拉取Docker镜像
Write-Host "`n正在拉取Docker镜像..." -ForegroundColor Cyan
try {
    Write-Host "  拉取Jupyter镜像..." -ForegroundColor White
    docker pull jupyter/pyspark-notebook:latest
    
    Write-Host "  拉取Spark镜像..." -ForegroundColor White
    docker pull bitnami/spark:3.4
    
    Write-Host "✓ Docker镜像拉取完成" -ForegroundColor Green
} catch {
    Write-Host "✗ 拉取Docker镜像时出错: $_" -ForegroundColor Red
    Write-Host "  请检查网络连接并重试" -ForegroundColor Yellow
}

# 创建示例数据文件
Write-Host "`n正在创建示例数据文件..." -ForegroundColor Cyan

# 创建示例CSV文件
$csvPath = Join-Path -Path $projectRoot -ChildPath "data/sample/sales_data.csv"
if (-not (Test-Path -Path $csvPath)) {
    $csvContent = @"
date,product_id,category,price,quantity,customer_id,region
2023-01-01,P001,Electronics,599.99,1,C1001,North
2023-01-01,P002,Books,29.99,2,C1002,South
2023-01-02,P003,Clothing,49.99,3,C1003,East
2023-01-02,P001,Electronics,599.99,1,C1004,West
2023-01-03,P004,Home,129.99,1,C1005,North
2023-01-03,P002,Books,29.99,4,C1006,South
2023-01-04,P005,Electronics,399.99,1,C1007,East
2023-01-04,P003,Clothing,49.99,2,C1001,West
2023-01-05,P001,Electronics,599.99,1,C1002,North
2023-01-05,P004,Home,129.99,2,C1003,South
"@
    $csvContent | Out-File -FilePath $csvPath -Encoding utf8
    Write-Host "  创建示例CSV文件: data/sample/sales_data.csv" -ForegroundColor White
}

# 创建示例JSON文件
$jsonPath = Join-Path -Path $projectRoot -ChildPath "data/sample/user_behavior.json"
if (-not (Test-Path -Path $jsonPath)) {
    $jsonContent = @"
{"timestamp": "2023-01-01T10:00:00", "user_id": "U1001", "action": "view", "item_id": "P001", "session_id": "S001"}
{"timestamp": "2023-01-01T10:01:30", "user_id": "U1001", "action": "add_to_cart", "item_id": "P001", "session_id": "S001"}
{"timestamp": "2023-01-01T10:05:00", "user_id": "U1001", "action": "purchase", "item_id": "P001", "session_id": "S001"}
{"timestamp": "2023-01-01T11:00:00", "user_id": "U1002", "action": "view", "item_id": "P002", "session_id": "S002"}
{"timestamp": "2023-01-01T11:02:00", "user_id": "U1002", "action": "view", "item_id": "P003", "session_id": "S002"}
{"timestamp": "2023-01-01T11:10:00", "user_id": "U1002", "action": "add_to_cart", "item_id": "P003", "session_id": "S002"}
{"timestamp": "2023-01-01T12:00:00", "user_id": "U1003", "action": "view", "item_id": "P001", "session_id": "S003"}
{"timestamp": "2023-01-01T12:05:00", "user_id": "U1003", "action": "view", "item_id": "P002", "session_id": "S003"}
{"timestamp": "2023-01-01T12:10:00", "user_id": "U1003", "action": "add_to_cart", "item_id": "P002", "session_id": "S003"}
{"timestamp": "2023-01-01T12:15:00", "user_id": "U1003", "action": "purchase", "item_id": "P002", "session_id": "S003"}
"@
    $jsonContent | Out-File -FilePath $jsonPath -Encoding utf8
    Write-Host "  创建示例JSON文件: data/sample/user_behavior.json" -ForegroundColor White
}

# 创建示例日志文件
$logPath = Join-Path -Path $projectRoot -ChildPath "data/sample/server_logs.txt"
if (-not (Test-Path -Path $logPath)) {
    $logContent = @"
[2023-01-01 00:00:01] INFO  Server started successfully
[2023-01-01 00:05:23] INFO  User login: user123
[2023-01-01 00:05:25] INFO  Page request: /home
[2023-01-01 00:06:10] INFO  API request: /api/products
[2023-01-01 00:06:12] ERROR Database connection failed
[2023-01-01 00:06:15] WARN  Retry attempt 1
[2023-01-01 00:06:18] INFO  Database connection established
[2023-01-01 00:10:23] INFO  User login: admin
[2023-01-01 00:10:25] INFO  Admin panel accessed
[2023-01-01 00:15:01] WARN  High memory usage detected
[2023-01-01 00:20:45] INFO  User logout: user123
[2023-01-01 00:25:18] ERROR 404 Page not found: /invalid-page
[2023-01-01 00:30:22] INFO  Scheduled backup started
[2023-01-01 00:35:15] INFO  Scheduled backup completed
[2023-01-01 00:40:03] INFO  User login: user456
[2023-01-01 00:40:08] INFO  Page request: /products
[2023-01-01 00:45:12] INFO  API request: /api/orders
[2023-01-01 00:50:30] WARN  Slow query detected: SELECT * FROM orders WHERE date > '2022-01-01'
[2023-01-01 00:55:45] INFO  User logout: admin
[2023-01-01 01:00:00] INFO  Daily maintenance started
"@
    $logContent | Out-File -FilePath $logPath -Encoding utf8
    Write-Host "  创建示例日志文件: data/sample/server_logs.txt" -ForegroundColor White
}

# 创建欢迎笔记本
$welcomeNotebookPath = Join-Path -Path $projectRoot -ChildPath "notebooks/00-welcome.ipynb"
if (-not (Test-Path -Path $welcomeNotebookPath)) {
    $notebookContent = @"
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 欢迎使用大数据学习平台\n",
    "\n",
    "这个Jupyter Notebook环境已经预配置了Apache Spark和相关工具，可以帮助您学习大数据处理技术。\n",
    "\n",
    "## 学习路径\n",
    "\n",
    "1. **Spark基础** - 从RDD、DataFrame和Dataset开始\n",
    "2. **Spark SQL** - 学习SQL查询和数据分析\n",
    "3. **Spark Streaming** - 了解流数据处理\n",
    "4. **实践项目** - 应用所学知识解决实际问题\n",
    "5. **Flink学习** - 探索另一个流处理框架\n",
    "\n",
    "## 环境信息\n",
    "\n",
    "- Jupyter Notebook with PySpark\n",
    "- Spark Master: spark://spark-master:7077\n",
    "- Spark Web UI: http://localhost:8080\n",
    "\n",
    "让我们先验证Spark环境是否正常工作："
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pyspark\n",
    "from pyspark.sql import SparkSession\n",
    "\n",
    "# 创建SparkSession\n",
    "spark = SparkSession.builder \\\n",
    "    .appName(\"WelcomeTest\") \\\n",
    "    .getOrCreate()\n",
    "\n",
    "# 显示Spark版本\n",
    "print(f\"Spark版本: {spark.version}\")\n",
    "\n",
    "# 显示Spark配置\n",
    "print(\"\\nSpark配置:\")\n",
    "for conf in spark.sparkContext.getConf().getAll():\n",
    "    print(f\"  {conf[0]}: {conf[1]}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 创建简单的RDD\n",
    "\n",
    "让我们创建一个简单的RDD并执行一些基本操作："
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# 创建RDD\n",
    "data = range(1, 101)\n",
    "rdd = spark.sparkContext.parallelize(data)\n",
    "\n",
    "# 执行一些转换\n",
    "squared = rdd.map(lambda x: x * x)\n",
    "filtered = squared.filter(lambda x: x % 2 == 0)\n",
    "\n",
    "# 执行动作\n",
    "result = filtered.collect()\n",
    "print(f\"结果包含 {len(result)} 个元素\")\n",
    "print(f\"前10个元素: {result[:10]}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 创建DataFrame\n",
    "\n",
    "现在让我们创建一个简单的DataFrame并执行一些操作："
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "from pyspark.sql import Row\n",
    "from pyspark.sql.functions import col\n",
    "\n",
    "# 创建DataFrame\n",
    "data = [\n",
    "    Row(id=1, name=\"张三\", age=25, city=\"北京\"),\n",
    "    Row(id=2, name=\"李四\", age=30, city=\"上海\"),\n",
    "    Row(id=3, name=\"王五\", age=35, city=\"广州\"),\n",
    "    Row(id=4, name=\"赵六\", age=40, city=\"深圳\"),\n",
    "    Row(id=5, name=\"钱七\", age=45, city=\"北京\")\n",
    "]\n",
    "df = spark.createDataFrame(data)\n",
    "\n",
    "# 显示DataFrame\n",
    "print(\"原始DataFrame:\")\n",
    "df.show()\n",
    "\n",
    "# 执行一些转换\n",
    "filtered_df = df.filter(col(\"age\") > 30)\n",
    "print(\"\\n年龄大于30的记录:\")\n",
    "filtered_df.show()\n",
    "\n",
    "# 按城市分组\n",
    "grouped_df = df.groupBy(\"city\").count()\n",
    "print(\"\\n按城市分组:\")\n",
    "grouped_df.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 读取示例数据\n",
    "\n",
    "让我们读取预先准备的示例数据："
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# 读取CSV文件\n",
    "sales_df = spark.read.option(\"header\", \"true\").option(\"inferSchema\", \"true\").csv(\"/home/jovyan/data/sample/sales_data.csv\")\n",
    "\n",
    "print(\"销售数据示例:\")\n",
    "sales_df.show()\n",
    "\n",
    "# 读取JSON文件\n",
    "user_df = spark.read.json(\"/home/jovyan/data/sample/user_behavior.json\")\n",
    "\n",
    "print(\"\\n用户行为数据示例:\")\n",
    "user_df.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 下一步\n",
    "\n",
    "恭喜！您已经成功验证了Spark环境并执行了一些基本操作。接下来，您可以探索以下笔记本：\n",
    "\n",
    "1. `01-spark-basics/rdd-fundamentals.ipynb` - 学习RDD的基础知识\n",
    "2. `01-spark-basics/dataframe-operations.ipynb` - 学习DataFrame操作\n",
    "3. `02-spark-sql/sql-basics.ipynb` - 学习Spark SQL基础\n",
    "\n",
    "祝您学习愉快！"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.10"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
"@
    $notebookContent | Out-File -FilePath $welcomeNotebookPath -Encoding utf8
    Write-Host "  创建欢迎笔记本: notebooks/00-welcome.ipynb" -ForegroundColor White
}

Write-Host "`n环境初始化完成！" -ForegroundColor Green
Write-Host "现在您可以运行 'scripts\start_environment.ps1' 来启动环境" -ForegroundColor White