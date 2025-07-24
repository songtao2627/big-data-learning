#!/usr/bin/env python3
"""
大数据学习平台 - 数据生成器
用于生成各种规模和类型的示例数据集
"""

import random
import json
import csv
import os
import datetime
from faker import Faker
import pandas as pd

# 初始化Faker
fake = Faker(['zh_CN'])  # 使用中文数据

class DataGenerator:
    """数据生成器类"""
    
    def __init__(self, output_dir="data"):
        self.output_dir = output_dir
        self.ensure_directories()
    
    def ensure_directories(self):
        """确保输出目录存在"""
        dirs = ['sample', 'medium', 'large']
        for dir_name in dirs:
            path = os.path.join(self.output_dir, dir_name)
            os.makedirs(path, exist_ok=True)
    
    def generate_ecommerce_data(self, num_records=10000, file_format='csv'):
        """生成电商交易数据"""
        print(f"生成 {num_records:,} 条电商交易数据...")
        
        categories = ['电子产品', '服装', '家居', '图书', '运动', '美妆', '食品']
        regions = ['华北', '华东', '华南', '华中', '西南', '西北', '东北']
        payment_methods = ['支付宝', '微信支付', '银行卡', '现金']
        
        data = []
        for i in range(num_records):
            record = {
                'transaction_id': f'T{i+1:08d}',
                'user_id': f'U{random.randint(1, num_records//10):06d}',
                'product_id': f'P{random.randint(1, 1000):04d}',
                'product_name': fake.word() + random.choice(['手机', '电脑', '衣服', '鞋子', '包包']),
                'category': random.choice(categories),
                'price': round(random.uniform(10, 2000), 2),
                'quantity': random.randint(1, 5),
                'discount': round(random.uniform(0, 0.3), 2),
                'payment_method': random.choice(payment_methods),
                'region': random.choice(regions),
                'city': fake.city(),
                'timestamp': fake.date_time_between(start_date='-1y', end_date='now').isoformat(),
                'user_age': random.randint(18, 65),
                'user_gender': random.choice(['男', '女']),
                'is_member': random.choice([True, False]),
                'rating': random.randint(1, 5)
            }
            
            # 计算总金额
            record['total_amount'] = round(record['price'] * record['quantity'] * (1 - record['discount']), 2)
            
            data.append(record)
        
        # 保存数据
        size_dir = 'medium' if num_records > 1000 else 'sample'
        if file_format == 'csv':
            filename = os.path.join(self.output_dir, size_dir, 'ecommerce_transactions.csv')
            with open(filename, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=data[0].keys())
                writer.writeheader()
                writer.writerows(data)
        elif file_format == 'json':
            filename = os.path.join(self.output_dir, size_dir, 'ecommerce_transactions.json')
            with open(filename, 'w', encoding='utf-8') as f:
                for record in data:
                    f.write(json.dumps(record, ensure_ascii=False) + '\n')
        
        print(f"电商数据已保存到: {filename}")
        return filename
    
    def generate_user_behavior_data(self, num_records=50000, file_format='json'):
        """生成用户行为数据"""
        print(f"生成 {num_records:,} 条用户行为数据...")
        
        actions = ['view', 'click', 'add_to_cart', 'purchase', 'share', 'favorite']
        pages = ['首页', '商品页', '购物车', '个人中心', '搜索页', '分类页']
        devices = ['PC', 'Mobile', 'Tablet']
        browsers = ['Chrome', 'Safari', 'Firefox', 'Edge']
        
        data = []
        for i in range(num_records):
            record = {
                'event_id': f'E{i+1:08d}',
                'user_id': f'U{random.randint(1, num_records//20):06d}',
                'session_id': f'S{random.randint(1, num_records//5):08d}',
                'timestamp': fake.date_time_between(start_date='-30d', end_date='now').isoformat(),
                'action': random.choice(actions),
                'page': random.choice(pages),
                'item_id': f'P{random.randint(1, 1000):04d}' if random.random() > 0.3 else None,
                'device': random.choice(devices),
                'browser': random.choice(browsers),
                'ip_address': fake.ipv4(),
                'duration': random.randint(1, 300),  # 停留时间（秒）
                'referrer': fake.url() if random.random() > 0.5 else None,
                'user_agent': fake.user_agent()
            }
            data.append(record)
        
        # 保存数据
        size_dir = 'medium' if num_records > 10000 else 'sample'
        filename = os.path.join(self.output_dir, size_dir, f'user_behavior.{file_format}')
        
        if file_format == 'json':
            with open(filename, 'w', encoding='utf-8') as f:
                for record in data:
                    f.write(json.dumps(record, ensure_ascii=False) + '\n')
        elif file_format == 'csv':
            with open(filename, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=data[0].keys())
                writer.writeheader()
                writer.writerows(data)
        
        print(f"用户行为数据已保存到: {filename}")
        return filename
    
    def generate_sensor_data(self, num_records=100000, file_format='csv'):
        """生成传感器数据"""
        print(f"生成 {num_records:,} 条传感器数据...")
        
        sensor_types = ['温度', '湿度', '压力', '光照', '噪音', 'PM2.5']
        locations = ['北京', '上海', '广州', '深圳', '杭州', '成都', '武汉']
        
        data = []
        base_time = datetime.datetime.now() - datetime.timedelta(days=30)
        
        for i in range(num_records):
            sensor_type = random.choice(sensor_types)
            
            # 根据传感器类型生成合理的数值范围
            if sensor_type == '温度':
                value = round(random.uniform(-10, 40), 1)
                unit = '°C'
            elif sensor_type == '湿度':
                value = round(random.uniform(20, 90), 1)
                unit = '%'
            elif sensor_type == '压力':
                value = round(random.uniform(950, 1050), 1)
                unit = 'hPa'
            elif sensor_type == '光照':
                value = round(random.uniform(0, 100000), 0)
                unit = 'lux'
            elif sensor_type == '噪音':
                value = round(random.uniform(30, 100), 1)
                unit = 'dB'
            else:  # PM2.5
                value = round(random.uniform(0, 300), 1)
                unit = 'μg/m³'
            
            record = {
                'sensor_id': f'S{random.randint(1, 1000):04d}',
                'sensor_type': sensor_type,
                'location': random.choice(locations),
                'timestamp': (base_time + datetime.timedelta(minutes=i//10)).isoformat(),
                'value': value,
                'unit': unit,
                'status': random.choice(['正常', '异常', '维护']) if random.random() > 0.9 else '正常',
                'battery_level': random.randint(10, 100),
                'signal_strength': random.randint(-100, -30)
            }
            data.append(record)
        
        # 保存数据
        size_dir = 'large' if num_records > 50000 else 'medium'
        filename = os.path.join(self.output_dir, size_dir, f'sensor_data.{file_format}')
        
        if file_format == 'csv':
            with open(filename, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=data[0].keys())
                writer.writeheader()
                writer.writerows(data)
        elif file_format == 'json':
            with open(filename, 'w', encoding='utf-8') as f:
                for record in data:
                    f.write(json.dumps(record, ensure_ascii=False) + '\n')
        
        print(f"传感器数据已保存到: {filename}")
        return filename
    
    def generate_log_data(self, num_records=20000, file_format='txt'):
        """生成服务器日志数据"""
        print(f"生成 {num_records:,} 条服务器日志数据...")
        
        log_levels = ['INFO', 'WARN', 'ERROR', 'DEBUG']
        services = ['user-service', 'order-service', 'payment-service', 'inventory-service']
        actions = ['login', 'logout', 'create_order', 'payment', 'search', 'view_product']
        
        data = []
        base_time = datetime.datetime.now() - datetime.timedelta(days=7)
        
        for i in range(num_records):
            timestamp = base_time + datetime.timedelta(seconds=i*2)
            level = random.choice(log_levels)
            service = random.choice(services)
            action = random.choice(actions)
            
            # 根据日志级别生成不同的消息
            if level == 'ERROR':
                messages = [
                    f"Database connection failed for {service}",
                    f"Timeout occurred in {action} operation",
                    f"Authentication failed for user",
                    f"Service {service} is unavailable"
                ]
            elif level == 'WARN':
                messages = [
                    f"High memory usage detected in {service}",
                    f"Slow query detected: {action}",
                    f"Rate limit exceeded for user",
                    f"Cache miss for key: {action}"
                ]
            else:
                messages = [
                    f"User performed {action} successfully",
                    f"Service {service} started successfully",
                    f"Request processed in {random.randint(10, 500)}ms",
                    f"Cache updated for {action}"
                ]
            
            message = random.choice(messages)
            
            log_entry = f"[{timestamp.strftime('%Y-%m-%d %H:%M:%S')}] {level:5} [{service}] {message}"
            
            # 添加一些额外信息
            if random.random() > 0.7:
                log_entry += f" - User: U{random.randint(1000, 9999)}"
            if random.random() > 0.8:
                log_entry += f" - IP: {fake.ipv4()}"
            
            data.append(log_entry)
        
        # 保存数据
        size_dir = 'medium' if num_records > 5000 else 'sample'
        filename = os.path.join(self.output_dir, size_dir, f'server_logs_large.{file_format}')
        
        with open(filename, 'w', encoding='utf-8') as f:
            for entry in data:
                f.write(entry + '\n')
        
        print(f"服务器日志已保存到: {filename}")
        return filename
    
    def generate_financial_data(self, num_records=30000, file_format='csv'):
        """生成金融交易数据"""
        print(f"生成 {num_records:,} 条金融交易数据...")
        
        transaction_types = ['转账', '支付', '充值', '提现', '投资', '理财']
        currencies = ['CNY', 'USD', 'EUR', 'JPY', 'GBP']
        channels = ['网银', '手机银行', 'ATM', '柜台', '第三方支付']
        
        data = []
        for i in range(num_records):
            record = {
                'transaction_id': f'FT{i+1:08d}',
                'account_id': f'A{random.randint(1, num_records//50):06d}',
                'transaction_type': random.choice(transaction_types),
                'amount': round(random.uniform(1, 100000), 2),
                'currency': random.choice(currencies),
                'channel': random.choice(channels),
                'timestamp': fake.date_time_between(start_date='-90d', end_date='now').isoformat(),
                'merchant_id': f'M{random.randint(1, 1000):04d}' if random.random() > 0.3 else None,
                'location': fake.city(),
                'status': random.choice(['成功', '失败', '处理中']) if random.random() > 0.95 else '成功',
                'risk_score': round(random.uniform(0, 1), 3),
                'fee': round(random.uniform(0, 50), 2),
                'balance_before': round(random.uniform(1000, 50000), 2),
                'balance_after': 0  # 将在后面计算
            }
            
            # 计算交易后余额
            if record['transaction_type'] in ['转账', '支付', '提现']:
                record['balance_after'] = record['balance_before'] - record['amount'] - record['fee']
            else:
                record['balance_after'] = record['balance_before'] + record['amount'] - record['fee']
            
            record['balance_after'] = round(record['balance_after'], 2)
            
            data.append(record)
        
        # 保存数据
        size_dir = 'medium' if num_records > 10000 else 'sample'
        filename = os.path.join(self.output_dir, size_dir, f'financial_transactions.{file_format}')
        
        if file_format == 'csv':
            with open(filename, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=data[0].keys())
                writer.writeheader()
                writer.writerows(data)
        elif file_format == 'parquet':
            df = pd.DataFrame(data)
            filename = filename.replace('.csv', '.parquet')
            df.to_parquet(filename, index=False)
        
        print(f"金融交易数据已保存到: {filename}")
        return filename
    
    def generate_all_datasets(self):
        """生成所有数据集"""
        print("开始生成所有示例数据集...")
        
        generated_files = []
        
        # 小型数据集
        generated_files.append(self.generate_ecommerce_data(1000, 'csv'))
        generated_files.append(self.generate_user_behavior_data(5000, 'json'))
        generated_files.append(self.generate_log_data(2000, 'txt'))
        
        # 中型数据集
        generated_files.append(self.generate_ecommerce_data(50000, 'csv'))
        generated_files.append(self.generate_user_behavior_data(100000, 'json'))
        generated_files.append(self.generate_sensor_data(80000, 'csv'))
        generated_files.append(self.generate_log_data(20000, 'txt'))
        generated_files.append(self.generate_financial_data(30000, 'csv'))
        
        # 大型数据集
        generated_files.append(self.generate_sensor_data(500000, 'csv'))
        
        print(f"\n✅ 所有数据集生成完成！共生成 {len(generated_files)} 个文件:")
        for file in generated_files:
            print(f"  - {file}")
        
        return generated_files

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='大数据学习平台数据生成器')
    parser.add_argument('--output-dir', default='data', help='输出目录')
    parser.add_argument('--dataset', choices=['ecommerce', 'user_behavior', 'sensor', 'log', 'financial', 'all'], 
                       default='all', help='要生成的数据集类型')
    parser.add_argument('--size', type=int, default=10000, help='记录数量')
    parser.add_argument('--format', choices=['csv', 'json', 'txt', 'parquet'], default='csv', help='文件格式')
    
    args = parser.parse_args()
    
    generator = DataGenerator(args.output_dir)
    
    if args.dataset == 'all':
        generator.generate_all_datasets()
    elif args.dataset == 'ecommerce':
        generator.generate_ecommerce_data(args.size, args.format)
    elif args.dataset == 'user_behavior':
        generator.generate_user_behavior_data(args.size, args.format)
    elif args.dataset == 'sensor':
        generator.generate_sensor_data(args.size, args.format)
    elif args.dataset == 'log':
        generator.generate_log_data(args.size, args.format)
    elif args.dataset == 'financial':
        generator.generate_financial_data(args.size, args.format)

if __name__ == '__main__':
    main()