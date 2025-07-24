# Spark调试和故障排除指南

本文档提供Spark应用程序调试和故障排除的实用指南，帮助您快速识别和解决常见问题。

## 1. 常见错误类型

### 1.1 内存相关错误

#### OutOfMemoryError
```
java.lang.OutOfMemoryError: Java heap space
```

**原因分析：**
- 驱动器或执行器内存不足
- 数据倾斜导致某个分区数据过大
- 缓存了过多数据

**解决方案：**
```python
# 增加驱动器内存
spark.conf.set("spark.driver.memory", "4g")

# 增加执行器内存
spark.conf.set("spark.executor.memory", "4g")

# 调整内存分配比例
spark.conf.set("spark.memory.fraction", "0.8")
```

#### GC Overhead Limit Exceeded
```
java.lang.OutOfMemoryError: GC overhead limit exceeded
```

**解决方案：**
```python
# 调整GC参数
spark.conf.set("spark.executor.extraJavaOptions", 
               "-XX:+UseG1GC -XX:MaxGCPauseMillis=200")

# 增加内存或减少数据量
spark.conf.set("spark.executor.memory", "6g")
```

### 1.2 序列化错误

#### Task Not Serializable
```
org.apache.spark.SparkException: Task not serializable
```

**原因分析：**
- 在闭包中使用了不可序列化的对象
- 引用了包含不可序列化字段的类

**解决方案：**
```python
# 错误示例
class MyClass:
    def __init__(self):
        self.non_serializable_field = some_object
    
    def process_data(self, df):
        return df.map(lambda x: self.non_serializable_field.process(x))

# 正确做法
class MyClass:
    def process_data(self, df):
        # 在函数内部创建或广播对象
        broadcast_obj = spark.sparkContext.broadcast(some_object)
        return df.map(lambda x: broadcast_obj.value.process(x))
```

### 1.3 文件系统错误

#### File Not Found
```
java.io.FileNotFoundException: File does not exist
```

**调试方法：**
```python
import os

def check_file_exists(file_path):
    """检查文件是否存在"""
    if os.path.exists(file_path):
        print(f"✅ 文件存在: {file_path}")
        print(f"文件大小: {os.path.getsize(file_path)} bytes")
    else:
        print(f"❌ 文件不存在: {file_path}")
        
        # 检查目录是否存在
        dir_path = os.path.dirname(file_path)
        if os.path.exists(dir_path):
            print(f"目录存在，文件列表:")
            for f in os.listdir(dir_path):
                print(f"  - {f}")
        else:
            print(f"目录也不存在: {dir_path}")

# 使用示例
check_file_exists("/home/jovyan/data/sample/sales_data.csv")
```

## 2. 调试工具和技术

### 2.1 日志分析

#### 设置日志级别
```python
# 设置不同的日志级别
spark.sparkContext.setLogLevel("INFO")  # DEBUG, INFO, WARN, ERROR

# 查看特定包的日志
import logging
logging.getLogger("org.apache.spark").setLevel(logging.DEBUG)
```

#### 自定义日志记录
```python
def debug_dataframe(df, name="DataFrame"):
    """调试DataFrame的详细信息"""
    print(f"=== {name} 调试信息 ===")
    
    # 基本信息
    print(f"分区数: {df.rdd.getNumPartitions()}")
    
    # Schema信息
    print("Schema:")
    df.printSchema()
    
    # 数据预览
    print("数据预览:")
    df.show(5, truncate=False)
    
    # 统计信息
    try:
        count = df.count()
        print(f"记录数: {count}")
    except Exception as e:
        print(f"计数失败: {str(e)}")
    
    print("=" * 40)

# 使用示例
df = spark.range(100).toDF("id")
debug_dataframe(df, "测试DataFrame")
```

### 2.2 执行计划分析

#### 查看执行计划
```python
def analyze_execution_plan(df, query_name="Query"):
    """分析查询执行计划"""
    print(f"=== {query_name} 执行计划分析 ===")
    
    # 逻辑计划
    print("逻辑计划:")
    print(df.explain(extended=False))
    
    # 物理计划
    print("\n物理计划:")
    print(df.explain(mode="formatted"))
    
    # 成本信息
    print("\n成本信息:")
    print(df.explain(mode="cost"))

# 使用示例
df = spark.range(1000).filter(col("id") > 500)
analyze_execution_plan(df, "过滤查询")
```

### 2.3 性能分析

#### 执行时间测量
```python
import time
from functools import wraps

def time_execution(func):
    """装饰器：测量函数执行时间"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        
        execution_time = end_time - start_time
        print(f"函数 {func.__name__} 执行时间: {execution_time:.2f} 秒")
        
        return result
    return wrapper

# 使用示例
@time_execution
def slow_operation():
    df = spark.range(1000000)
    return df.filter(col("id") % 2 == 0).count()

result = slow_operation()
```

## 3. 常见问题诊断

### 3.1 作业运行缓慢

#### 诊断步骤
```python
def diagnose_slow_job(spark):
    """诊断作业运行缓慢的原因"""
    print("=== 作业性能诊断 ===")
    
    # 检查资源配置
    print("1. 资源配置检查:")
    print(f"   执行器数量: {spark.conf.get('spark.executor.instances', '未设置')}")
    print(f"   执行器内存: {spark.conf.get('spark.executor.memory', '未设置')}")
    print(f"   执行器核心: {spark.conf.get('spark.executor.cores', '未设置')}")
    print(f"   驱动器内存: {spark.conf.get('spark.driver.memory', '未设置')}")
    
    # 检查并行度设置
    print("\n2. 并行度检查:")
    print(f"   默认并行度: {spark.sparkContext.defaultParallelism}")
    print(f"   Shuffle分区数: {spark.conf.get('spark.sql.shuffle.partitions', '200')}")
    
    # 检查序列化器
    print("\n3. 序列化器检查:")
    serializer = spark.conf.get('spark.serializer', '未设置')
    print(f"   序列化器: {serializer}")
    if 'Kryo' not in serializer:
        print("   ⚠️  建议使用KryoSerializer提高性能")
    
    # 检查压缩设置
    print("\n4. 压缩设置检查:")
    print(f"   RDD压缩: {spark.conf.get('spark.rdd.compress', 'false')}")
    print(f"   Shuffle压缩: {spark.conf.get('spark.shuffle.compress', 'true')}")
    
    print("=" * 40)

# 使用示例
diagnose_slow_job(spark)
```

### 3.2 数据倾斜问题

#### 检测数据倾斜
```python
def detect_data_skew(df, key_column=None):
    """检测数据倾斜问题"""
    print("=== 数据倾斜检测 ===")
    
    # 检查分区倾斜
    def get_partition_sizes(df):
        return df.rdd.mapPartitionsWithIndex(
            lambda idx, iterator: [(idx, sum(1 for _ in iterator))]
        ).collect()
    
    partition_sizes = get_partition_sizes(df)
    sizes = [size for _, size in partition_sizes]
    
    if sizes:
        avg_size = sum(sizes) / len(sizes)
        max_size = max(sizes)
        min_size = min(sizes)
        
        print(f"分区数量: {len(sizes)}")
        print(f"平均大小: {avg_size:.0f}")
        print(f"最大分区: {max_size}")
        print(f"最小分区: {min_size}")
        print(f"倾斜比例: {max_size/avg_size:.2f}" if avg_size > 0 else "无法计算")
        
        if max_size > avg_size * 3:
            print("⚠️  检测到严重分区倾斜！")
            print("建议解决方案:")
            print("  1. 重新分区: df.repartition(num_partitions)")
            print("  2. 使用salting技术")
            print("  3. 调整分区键")
    
    # 如果指定了键列，检查键值倾斜
    if key_column and key_column in df.columns:
        print(f"\n键值倾斜检测 ({key_column}):")
        key_counts = df.groupBy(key_column).count().orderBy(desc("count"))
        top_keys = key_counts.limit(5).collect()
        
        total_records = df.count()
        
        for row in top_keys:
            key_val = row[key_column]
            count = row['count']
            percentage = (count / total_records) * 100
            print(f"  {key_val}: {count} ({percentage:.1f}%)")
    
    print("=" * 40)

# 使用示例
df = spark.range(10000).withColumn("key", col("id") % 10)
detect_data_skew(df, "key")
```

### 3.3 内存泄漏检测

#### 监控内存使用
```python
def monitor_memory_usage(spark, operation_func, operation_name):
    """监控操作的内存使用情况"""
    print(f"=== {operation_name} 内存监控 ===")
    
    # 获取初始内存状态
    def get_memory_info():
        executor_infos = spark.sparkContext.statusTracker().getExecutorInfos()
        total_used = sum(info.memoryUsed for info in executor_infos)
        total_max = sum(info.maxMemory for info in executor_infos)
        return total_used, total_max
    
    initial_used, total_max = get_memory_info()
    print(f"操作前内存使用: {initial_used / (1024**3):.2f} GB")
    
    # 执行操作
    start_time = time.time()
    result = operation_func()
    end_time = time.time()
    
    # 获取操作后内存状态
    final_used, _ = get_memory_info()
    print(f"操作后内存使用: {final_used / (1024**3):.2f} GB")
    print(f"内存增长: {(final_used - initial_used) / (1024**3):.2f} GB")
    print(f"执行时间: {end_time - start_time:.2f} 秒")
    
    # 检查是否有内存泄漏风险
    memory_growth = final_used - initial_used
    if memory_growth > total_max * 0.1:  # 增长超过10%
        print("⚠️  检测到显著内存增长，可能存在内存泄漏")
        print("建议检查:")
        print("  1. 是否有未释放的缓存")
        print("  2. 是否有循环引用")
        print("  3. 是否需要调用unpersist()")
    
    print("=" * 40)
    return result

# 使用示例
def memory_intensive_operation():
    df = spark.range(100000).cache()
    result = df.count()
    # df.unpersist()  # 取消注释以释放缓存
    return result

result = monitor_memory_usage(spark, memory_intensive_operation, "缓存操作")
```

## 4. 故障排除工具

### 4.1 健康检查脚本

```python
def spark_health_check(spark):
    """Spark应用程序健康检查"""
    print("=== Spark健康检查 ===")
    
    health_status = {
        'overall': 'healthy',
        'issues': []
    }
    
    try:
        # 检查SparkContext状态
        sc = spark.sparkContext
        if sc.isStopped():
            health_status['issues'].append("SparkContext已停止")
            health_status['overall'] = 'critical'
        else:
            print("✅ SparkContext运行正常")
        
        # 检查执行器状态
        executor_infos = sc.statusTracker().getExecutorInfos()
        active_executors = len([e for e in executor_infos if e.isActive])
        
        if active_executors == 0:
            health_status['issues'].append("没有活跃的执行器")
            health_status['overall'] = 'critical'
        else:
            print(f"✅ {active_executors} 个执行器运行正常")
        
        # 检查失败的作业
        failed_jobs = [job for job in sc.statusTracker().getActiveJobIds() 
                      if sc.statusTracker().getJobInfo(job) and 
                      sc.statusTracker().getJobInfo(job).status == 'FAILED']
        
        if failed_jobs:
            health_status['issues'].append(f"{len(failed_jobs)} 个作业失败")
            health_status['overall'] = 'warning'
        else:
            print("✅ 没有失败的作业")
        
        # 检查内存使用
        total_used = sum(info.memoryUsed for info in executor_infos)
        total_max = sum(info.maxMemory for info in executor_infos)
        
        if total_max > 0:
            memory_usage = (total_used / total_max) * 100
            if memory_usage > 90:
                health_status['issues'].append(f"内存使用率过高: {memory_usage:.1f}%")
                health_status['overall'] = 'warning'
            else:
                print(f"✅ 内存使用正常: {memory_usage:.1f}%")
        
    except Exception as e:
        health_status['issues'].append(f"健康检查异常: {str(e)}")
        health_status['overall'] = 'critical'
    
    # 输出总结
    status_icon = {
        'healthy': '✅',
        'warning': '⚠️',
        'critical': '❌'
    }
    
    print(f"\n{status_icon[health_status['overall']]} 总体状态: {health_status['overall'].upper()}")
    
    if health_status['issues']:
        print("发现的问题:")
        for issue in health_status['issues']:
            print(f"  - {issue}")
    
    print("=" * 40)
    return health_status

# 使用示例
health_status = spark_health_check(spark)
```

### 4.2 错误恢复策略

```python
def robust_spark_operation(operation_func, max_retries=3, backoff_factor=2):
    """带重试机制的Spark操作"""
    
    for attempt in range(max_retries):
        try:
            print(f"尝试执行操作 (第 {attempt + 1} 次)")
            result = operation_func()
            print("✅ 操作成功完成")
            return result
            
        except Exception as e:
            error_type = type(e).__name__
            error_msg = str(e)
            
            print(f"❌ 操作失败: {error_type}")
            print(f"错误信息: {error_msg}")
            
            if attempt < max_retries - 1:
                wait_time = backoff_factor ** attempt
                print(f"等待 {wait_time} 秒后重试...")
                time.sleep(wait_time)
                
                # 根据错误类型采取不同的恢复策略
                if "OutOfMemoryError" in error_msg:
                    print("检测到内存错误，尝试清理缓存...")
                    spark.catalog.clearCache()
                    
                elif "FileNotFoundException" in error_msg:
                    print("检测到文件错误，请检查文件路径...")
                    
                elif "ConnectionException" in error_msg:
                    print("检测到连接错误，可能是网络问题...")
            else:
                print(f"操作失败，已达到最大重试次数 ({max_retries})")
                raise e

# 使用示例
def risky_operation():
    # 模拟可能失败的操作
    import random
    if random.random() < 0.7:  # 70%的失败率
        raise Exception("模拟的随机错误")
    return "操作成功"

try:
    result = robust_spark_operation(risky_operation, max_retries=3)
    print(f"最终结果: {result}")
except Exception as e:
    print(f"操作最终失败: {e}")
```

## 5. 调试最佳实践

### 5.1 调试检查清单

```python
def debugging_checklist():
    """Spark调试检查清单"""
    
    checklist = [
        {
            'category': '环境检查',
            'items': [
                '检查Spark版本兼容性',
                '验证Java版本',
                '确认依赖包版本',
                '检查集群资源可用性'
            ]
        },
        {
            'category': '配置检查',
            'items': [
                '验证内存配置',
                '检查并行度设置',
                '确认序列化器配置',
                '检查网络配置'
            ]
        },
        {
            'category': '数据检查',
            'items': [
                '验证数据源可访问性',
                '检查数据格式和Schema',
                '分析数据分布和倾斜',
                '确认数据质量'
            ]
        },
        {
            'category': '代码检查',
            'items': [
                '检查序列化问题',
                '验证UDF实现',
                '确认资源释放',
                '检查异常处理'
            ]
        }
    ]
    
    print("=== Spark调试检查清单 ===")
    for category in checklist:
        print(f"\n{category['category']}:")
        for item in category['items']:
            print(f"  □ {item}")
    
    print("\n" + "=" * 40)

# 显示检查清单
debugging_checklist()
```

### 5.2 调试工具集成

```python
class SparkDebugger:
    """Spark调试工具类"""
    
    def __init__(self, spark):
        self.spark = spark
        self.sc = spark.sparkContext
    
    def profile_operation(self, operation_func, operation_name):
        """分析操作性能"""
        print(f"=== 分析 {operation_name} ===")
        
        # 记录开始状态
        start_time = time.time()
        initial_jobs = len(self.sc.statusTracker().getActiveJobIds())
        
        # 执行操作
        result = operation_func()
        
        # 记录结束状态
        end_time = time.time()
        final_jobs = len(self.sc.statusTracker().getActiveJobIds())
        
        # 输出分析结果
        execution_time = end_time - start_time
        jobs_created = final_jobs - initial_jobs
        
        print(f"执行时间: {execution_time:.2f} 秒")
        print(f"创建作业数: {jobs_created}")
        
        # 获取最近的作业信息
        if jobs_created > 0:
            recent_jobs = self.sc.statusTracker().getActiveJobIds()[-jobs_created:]
            for job_id in recent_jobs:
                job_info = self.sc.statusTracker().getJobInfo(job_id)
                if job_info:
                    print(f"作业 {job_id}: {job_info.status}")
        
        print("=" * 40)
        return result
    
    def analyze_dataframe(self, df, name="DataFrame"):
        """分析DataFrame"""
        print(f"=== 分析 {name} ===")
        
        # 基本信息
        print(f"分区数: {df.rdd.getNumPartitions()}")
        
        # Schema
        print("Schema:")
        df.printSchema()
        
        # 执行计划
        print("执行计划:")
        df.explain(True)
        
        print("=" * 40)
    
    def memory_snapshot(self):
        """内存快照"""
        executor_infos = self.sc.statusTracker().getExecutorInfos()
        
        print("=== 内存快照 ===")
        for executor in executor_infos:
            used_gb = executor.memoryUsed / (1024**3)
            max_gb = executor.maxMemory / (1024**3)
            usage_pct = (executor.memoryUsed / executor.maxMemory) * 100 if executor.maxMemory > 0 else 0
            
            print(f"执行器 {executor.executorId}:")
            print(f"  内存使用: {used_gb:.2f}GB / {max_gb:.2f}GB ({usage_pct:.1f}%)")
        
        print("=" * 40)

# 使用示例
debugger = SparkDebugger(spark)

# 分析操作性能
def test_operation():
    return spark.range(10000).filter(col("id") > 5000).count()

result = debugger.profile_operation(test_operation, "过滤计数操作")

# 内存快照
debugger.memory_snapshot()
```

## 6. 总结

本调试指南涵盖了Spark应用程序调试和故障排除的主要方面：

1. **常见错误识别**：内存错误、序列化错误、文件系统错误
2. **调试工具使用**：日志分析、执行计划分析、性能测量
3. **问题诊断方法**：作业缓慢、数据倾斜、内存泄漏
4. **故障排除工具**：健康检查、错误恢复策略
5. **调试最佳实践**：检查清单、工具集成

通过系统性地应用这些调试技术，您可以更快地识别和解决Spark应用程序中的问题，提高开发效率和应用程序的稳定性。