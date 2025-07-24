"""
日志解析器模块

这个模块提供了用于解析和分析服务器日志的工具函数。
"""

import re
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.functions import *
from pyspark.sql.types import *

class LogParser:
    """日志解析器类"""
    
    def __init__(self, spark: SparkSession):
        """
        初始化日志解析器
        
        Args:
            spark: SparkSession实例
        """
        self.spark = spark
        self.log_patterns = {
            'standard': r'\[(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\]\s+(\w+)\s+(.*)',
            'apache': r'(\S+)\s+\S+\s+\S+\s+\[([^\]]+)\]\s+"([^"]+)"\s+(\d+)\s+(\d+)',
            'nginx': r'(\S+)\s+-\s+-\s+\[([^\]]+)\]\s+"([^"]+)"\s+(\d+)\s+(\d+)\s+"([^"]*)"\s+"([^"]*)"'
        }
    
    def parse_standard_log(self, line: str) -> Optional[Dict]:
        """
        解析标准格式的日志行
        
        Args:
            line: 日志行字符串
            
        Returns:
            解析后的字典，如果解析失败返回None
        """
        pattern = self.log_patterns['standard']
        match = re.match(pattern, line)
        
        if match:
            timestamp_str, level, message = match.groups()
            
            # 提取更多信息
            user_match = re.search(r'User login: (\w+)', message)
            user_id = user_match.group(1) if user_match else None
            
            page_match = re.search(r'Page request: (\S+)', message)
            page_url = page_match.group(1) if page_match else None
            
            api_match = re.search(r'API request: (\S+)', message)
            api_url = api_match.group(1) if api_match else None
            
            error_code_match = re.search(r'(\d{3})\s+', message)
            error_code = error_code_match.group(1) if error_code_match else None
            
            return {
                'timestamp': timestamp_str,
                'level': level,
                'message': message,
                'user_id': user_id,
                'page_url': page_url,
                'api_url': api_url,
                'error_code': error_code
            }
        return None
    
    def parse_apache_log(self, line: str) -> Optional[Dict]:
        """
        解析Apache访问日志
        
        Args:
            line: 日志行字符串
            
        Returns:
            解析后的字典，如果解析失败返回None
        """
        pattern = self.log_patterns['apache']
        match = re.match(pattern, line)
        
        if match:
            ip, timestamp_str, request, status_code, size = match.groups()
            
            # 解析请求
            request_parts = request.split()
            method = request_parts[0] if len(request_parts) > 0 else None
            url = request_parts[1] if len(request_parts) > 1 else None
            protocol = request_parts[2] if len(request_parts) > 2 else None
            
            return {
                'ip_address': ip,
                'timestamp': timestamp_str,
                'method': method,
                'url': url,
                'protocol': protocol,
                'status_code': int(status_code),
                'response_size': int(size) if size != '-' else 0
            }
        return None
    
    def load_and_parse_logs(self, file_path: str, log_format: str = 'standard') -> DataFrame:
        """
        加载并解析日志文件
        
        Args:
            file_path: 日志文件路径
            log_format: 日志格式 ('standard', 'apache', 'nginx')
            
        Returns:
            解析后的DataFrame
        """
        # 读取日志文件
        logs_rdd = self.spark.sparkContext.textFile(file_path)
        
        # 选择解析函数
        if log_format == 'standard':
            parse_func = self.parse_standard_log
        elif log_format == 'apache':
            parse_func = self.parse_apache_log
        else:
            raise ValueError(f"不支持的日志格式: {log_format}")
        
        # 解析日志
        parsed_logs = logs_rdd.map(parse_func).filter(lambda x: x is not None)
        
        # 转换为DataFrame
        if parsed_logs.isEmpty():
            return self.spark.createDataFrame([], StructType([]))
        
        return self.spark.createDataFrame(parsed_logs)
    
    def analyze_log_levels(self, log_df: DataFrame) -> DataFrame:
        """
        分析日志级别分布
        
        Args:
            log_df: 日志DataFrame
            
        Returns:
            日志级别统计DataFrame
        """
        return log_df.groupBy("level").count().orderBy(desc("count"))
    
    def analyze_errors(self, log_df: DataFrame) -> Tuple[DataFrame, DataFrame]:
        """
        分析错误日志
        
        Args:
            log_df: 日志DataFrame
            
        Returns:
            (错误日志DataFrame, 错误类型统计DataFrame)
        """
        error_logs = log_df.filter(col("level") == "ERROR")
        
        # 错误类型分类
        error_patterns = error_logs.withColumn(
            "error_type",
            when(col("message").contains("Database"), "Database Error")
            .when(col("message").contains("404"), "404 Not Found")
            .when(col("message").contains("500"), "500 Internal Error")
            .when(col("message").contains("Service unavailable"), "Service Unavailable")
            .when(col("message").contains("connection"), "Connection Error")
            .otherwise("Other Error")
        )
        
        error_type_counts = error_patterns.groupBy("error_type").count().orderBy(desc("count"))
        
        return error_logs, error_type_counts
    
    def analyze_user_activity(self, log_df: DataFrame) -> Dict[str, DataFrame]:
        """
        分析用户活动
        
        Args:
            log_df: 日志DataFrame
            
        Returns:
            包含各种用户活动统计的字典
        """
        results = {}
        
        # 用户登录统计
        login_logs = log_df.filter(col("user_id").isNotNull())
        results['user_logins'] = login_logs.groupBy("user_id").count().orderBy(desc("count"))
        
        # 页面访问统计
        page_logs = log_df.filter(col("page_url").isNotNull())
        results['page_access'] = page_logs.groupBy("page_url").count().orderBy(desc("count"))
        
        # API访问统计
        api_logs = log_df.filter(col("api_url").isNotNull())
        results['api_access'] = api_logs.groupBy("api_url").count().orderBy(desc("count"))
        
        return results
    
    def analyze_time_patterns(self, log_df: DataFrame) -> Dict[str, DataFrame]:
        """
        分析时间模式
        
        Args:
            log_df: 日志DataFrame
            
        Returns:
            包含时间模式分析的字典
        """
        results = {}
        
        # 转换时间戳
        log_df_with_time = log_df.withColumn(
            "timestamp_parsed", 
            to_timestamp(col("timestamp"), "yyyy-MM-dd HH:mm:ss")
        ).withColumn(
            "hour", hour(col("timestamp_parsed"))
        ).withColumn(
            "day_of_week", date_format(col("timestamp_parsed"), "EEEE")
        )
        
        # 按小时统计
        results['hourly'] = log_df_with_time.groupBy("hour").count().orderBy("hour")
        
        # 按星期统计
        results['daily'] = log_df_with_time.groupBy("day_of_week").count().orderBy("day_of_week")
        
        # 按日志级别和小时统计
        results['level_hourly'] = log_df_with_time.groupBy("level", "hour").count().orderBy("level", "hour")
        
        return results
    
    def detect_anomalies(self, log_df: DataFrame) -> Dict[str, DataFrame]:
        """
        检测异常模式
        
        Args:
            log_df: 日志DataFrame
            
        Returns:
            包含异常检测结果的字典
        """
        results = {}
        
        # 检测高频错误
        error_logs = log_df.filter(col("level") == "ERROR")
        if error_logs.count() > 0:
            results['frequent_errors'] = error_logs.groupBy("message").count().filter(col("count") > 1).orderBy(desc("count"))
        
        # 检测可疑用户活动（短时间内大量请求）
        user_activity = log_df.filter(col("user_id").isNotNull())
        if user_activity.count() > 0:
            results['suspicious_users'] = user_activity.groupBy("user_id").count().filter(col("count") > 5).orderBy(desc("count"))
        
        # 检测系统性能问题
        performance_logs = log_df.filter(
            col("message").contains("memory") | 
            col("message").contains("CPU") | 
            col("message").contains("Slow query")
        )
        if performance_logs.count() > 0:
            results['performance_issues'] = performance_logs.select("timestamp", "level", "message")
        
        return results
    
    def generate_summary_report(self, log_df: DataFrame) -> Dict:
        """
        生成日志分析摘要报告
        
        Args:
            log_df: 日志DataFrame
            
        Returns:
            摘要报告字典
        """
        total_logs = log_df.count()
        
        # 基本统计
        level_stats = log_df.groupBy("level").count().collect()
        level_distribution = {row['level']: row['count'] for row in level_stats}
        
        # 错误统计
        error_count = log_df.filter(col("level") == "ERROR").count()
        warn_count = log_df.filter(col("level") == "WARN").count()
        
        # 用户活动统计
        unique_users = log_df.filter(col("user_id").isNotNull()).select("user_id").distinct().count()
        
        # 时间范围
        time_stats = log_df.select(
            min(col("timestamp")).alias("start_time"),
            max(col("timestamp")).alias("end_time")
        ).collect()[0]
        
        return {
            'total_logs': total_logs,
            'level_distribution': level_distribution,
            'error_count': error_count,
            'warning_count': warn_count,
            'error_rate': (error_count / total_logs * 100) if total_logs > 0 else 0,
            'warning_rate': (warn_count / total_logs * 100) if total_logs > 0 else 0,
            'unique_users': unique_users,
            'time_range': {
                'start': time_stats['start_time'],
                'end': time_stats['end_time']
            }
        }

class LogAnalyzer:
    """日志分析器类，提供高级分析功能"""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.parser = LogParser(spark)
    
    def run_complete_analysis(self, file_path: str, log_format: str = 'standard') -> Dict:
        """
        运行完整的日志分析
        
        Args:
            file_path: 日志文件路径
            log_format: 日志格式
            
        Returns:
            完整的分析结果字典
        """
        # 加载和解析日志
        log_df = self.parser.load_and_parse_logs(file_path, log_format)
        
        if log_df.count() == 0:
            return {'error': '没有找到有效的日志数据'}
        
        results = {}
        
        # 基本统计
        results['summary'] = self.parser.generate_summary_report(log_df)
        
        # 日志级别分析
        results['level_analysis'] = self.parser.analyze_log_levels(log_df)
        
        # 错误分析
        error_logs, error_types = self.parser.analyze_errors(log_df)
        results['error_analysis'] = {
            'error_logs': error_logs,
            'error_types': error_types
        }
        
        # 用户活动分析
        results['user_analysis'] = self.parser.analyze_user_activity(log_df)
        
        # 时间模式分析
        results['time_analysis'] = self.parser.analyze_time_patterns(log_df)
        
        # 异常检测
        results['anomaly_detection'] = self.parser.detect_anomalies(log_df)
        
        return results
    
    def export_results(self, results: Dict, output_dir: str):
        """
        导出分析结果
        
        Args:
            results: 分析结果字典
            output_dir: 输出目录
        """
        import os
        os.makedirs(output_dir, exist_ok=True)
        
        # 导出各种分析结果
        if 'level_analysis' in results:
            results['level_analysis'].coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{output_dir}/level_analysis")
        
        if 'error_analysis' in results:
            if 'error_logs' in results['error_analysis']:
                results['error_analysis']['error_logs'].coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{output_dir}/error_logs")
            if 'error_types' in results['error_analysis']:
                results['error_analysis']['error_types'].coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{output_dir}/error_types")
        
        if 'user_analysis' in results:
            for key, df in results['user_analysis'].items():
                df.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{output_dir}/{key}")
        
        if 'time_analysis' in results:
            for key, df in results['time_analysis'].items():
                df.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{output_dir}/time_{key}")

# 使用示例
if __name__ == "__main__":
    # 创建SparkSession
    spark = SparkSession.builder.appName("Log Analysis").getOrCreate()
    
    # 创建分析器
    analyzer = LogAnalyzer(spark)
    
    # 运行分析
    results = analyzer.run_complete_analysis("/home/jovyan/data/sample/server_logs.txt")
    
    # 导出结果
    analyzer.export_results(results, "/home/jovyan/output/log_analysis")
    
    # 打印摘要
    if 'summary' in results:
        print("=== 日志分析摘要 ===")
        summary = results['summary']
        print(f"总日志数: {summary['total_logs']}")
        print(f"错误率: {summary['error_rate']:.2f}%")
        print(f"警告率: {summary['warning_rate']:.2f}%")
        print(f"活跃用户: {summary['unique_users']}")
    
    spark.stop()