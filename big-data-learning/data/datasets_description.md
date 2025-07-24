# 数据集说明文档

本文档描述了大数据学习平台中提供的各种数据集，包括数据结构、用途和使用建议。

## 数据集分类

### 按规模分类

- **小型数据集 (sample/)**：1K-10K条记录，适合快速测试和学习基础概念
- **中型数据集 (medium/)**：10K-100K条记录，适合中级练习和性能测试
- **大型数据集 (large/)**：100K+条记录，适合高级练习和性能调优

### 按业务场景分类

1. **电商数据**：交易、用户行为、商品信息
2. **物联网数据**：传感器数据、设备状态
3. **金融数据**：交易记录、风险评估
4. **系统数据**：服务器日志、性能指标

## 详细数据集说明

### 1. 电商交易数据 (ecommerce_transactions)

**文件格式**: CSV, JSON  
**记录数量**: 1K (sample), 50K (medium)  
**更新频率**: 静态数据集

#### 数据结构
```
transaction_id: 交易ID (字符串)
user_id: 用户ID (字符串)
product_id: 商品ID (字符串)
product_name: 商品名称 (字符串)
category: 商品类别 (字符串)
price: 单价 (浮点数)
quantity: 数量 (整数)
discount: 折扣率 (浮点数, 0-1)
total_amount: 总金额 (浮点数)
payment_method: 支付方式 (字符串)
region: 地区 (字符串)
city: 城市 (字符串)
timestamp: 交易时间 (ISO格式字符串)
user_age: 用户年龄 (整数)
user_gender: 用户性别 (字符串)
is_member: 是否会员 (布尔值)
rating: 商品评分 (整数, 1-5)
```

#### 使用场景
- 销售分析和报表
- 用户行为分析
- 商品推荐系统
- 地区销售对比
- 会员价值分析

#### 示例查询
```sql
-- 按地区统计销售额
SELECT region, SUM(total_amount) as total_sales
FROM ecommerce_transactions
GROUP BY region
ORDER BY total_sales DESC;

-- 分析用户购买偏好
SELECT category, AVG(rating) as avg_rating, COUNT(*) as purchase_count
FROM ecommerce_transactions
GROUP BY category;
```

### 2. 用户行为数据 (user_behavior)

**文件格式**: JSON, CSV  
**记录数量**: 5K (sample), 100K (medium)  
**更新频率**: 实时流数据模拟

#### 数据结构
```
event_id: 事件ID (字符串)
user_id: 用户ID (字符串)
session_id: 会话ID (字符串)
timestamp: 事件时间 (ISO格式字符串)
action: 用户行为 (字符串: view, click, add_to_cart, purchase, share, favorite)
page: 页面名称 (字符串)
item_id: 商品ID (字符串, 可为空)
device: 设备类型 (字符串: PC, Mobile, Tablet)
browser: 浏览器 (字符串)
ip_address: IP地址 (字符串)
duration: 停留时间 (整数, 秒)
referrer: 来源页面 (字符串, 可为空)
user_agent: 用户代理 (字符串)
```

#### 使用场景
- 用户行为分析
- 转化率分析
- 页面性能分析
- 个性化推荐
- A/B测试分析

#### 示例查询
```sql
-- 计算转化率
WITH funnel AS (
  SELECT user_id,
    SUM(CASE WHEN action = 'view' THEN 1 ELSE 0 END) as views,
    SUM(CASE WHEN action = 'add_to_cart' THEN 1 ELSE 0 END) as add_to_cart,
    SUM(CASE WHEN action = 'purchase' THEN 1 ELSE 0 END) as purchases
  FROM user_behavior
  GROUP BY user_id
)
SELECT 
  AVG(add_to_cart / views) as view_to_cart_rate,
  AVG(purchases / add_to_cart) as cart_to_purchase_rate
FROM funnel
WHERE views > 0 AND add_to_cart > 0;
```

### 3. 传感器数据 (sensor_data)

**文件格式**: CSV, JSON  
**记录数量**: 80K (medium), 500K (large)  
**更新频率**: 时间序列数据

#### 数据结构
```
sensor_id: 传感器ID (字符串)
sensor_type: 传感器类型 (字符串: 温度, 湿度, 压力, 光照, 噪音, PM2.5)
location: 位置 (字符串)
timestamp: 采集时间 (ISO格式字符串)
value: 测量值 (浮点数)
unit: 单位 (字符串)
status: 设备状态 (字符串: 正常, 异常, 维护)
battery_level: 电池电量 (整数, 0-100)
signal_strength: 信号强度 (整数, -100到-30)
```

#### 使用场景
- 环境监控
- 异常检测
- 时间序列分析
- 预测性维护
- 数据质量分析

#### 示例查询
```sql
-- 检测异常温度读数
SELECT location, timestamp, value
FROM sensor_data
WHERE sensor_type = '温度' 
  AND (value < -20 OR value > 50)
ORDER BY timestamp DESC;

-- 计算每日平均值
SELECT 
  DATE(timestamp) as date,
  sensor_type,
  location,
  AVG(value) as avg_value,
  MIN(value) as min_value,
  MAX(value) as max_value
FROM sensor_data
GROUP BY DATE(timestamp), sensor_type, location;
```

### 4. 服务器日志数据 (server_logs)

**文件格式**: TXT  
**记录数量**: 2K (sample), 20K (medium)  
**更新频率**: 实时日志流

#### 数据格式
```
[YYYY-MM-DD HH:MM:SS] LEVEL [service-name] message - additional_info
```

#### 日志级别
- **INFO**: 正常操作信息
- **WARN**: 警告信息，需要注意但不影响正常运行
- **ERROR**: 错误信息，需要立即处理
- **DEBUG**: 调试信息，详细的执行过程

#### 使用场景
- 系统监控和告警
- 错误分析和故障排除
- 性能分析
- 安全审计
- 服务质量监控

#### 示例分析
```python
# 使用Spark分析日志
log_df = spark.read.text("server_logs_large.txt")

# 提取日志级别统计
log_levels = log_df.select(
    regexp_extract(col("value"), r"\] (\w+) \[", 1).alias("level")
).groupBy("level").count()

# 错误日志分析
error_logs = log_df.filter(col("value").contains("ERROR"))
```

### 5. 金融交易数据 (financial_transactions)

**文件格式**: CSV, Parquet  
**记录数量**: 30K (medium)  
**更新频率**: 准实时数据

#### 数据结构
```
transaction_id: 交易ID (字符串)
account_id: 账户ID (字符串)
transaction_type: 交易类型 (字符串: 转账, 支付, 充值, 提现, 投资, 理财)
amount: 交易金额 (浮点数)
currency: 货币类型 (字符串: CNY, USD, EUR, JPY, GBP)
channel: 交易渠道 (字符串: 网银, 手机银行, ATM, 柜台, 第三方支付)
timestamp: 交易时间 (ISO格式字符串)
merchant_id: 商户ID (字符串, 可为空)
location: 交易地点 (字符串)
status: 交易状态 (字符串: 成功, 失败, 处理中)
risk_score: 风险评分 (浮点数, 0-1)
fee: 手续费 (浮点数)
balance_before: 交易前余额 (浮点数)
balance_after: 交易后余额 (浮点数)
```

#### 使用场景
- 风险控制和反欺诈
- 交易模式分析
- 客户行为分析
- 合规监控
- 财务报表生成

#### 示例查询
```sql
-- 高风险交易检测
SELECT transaction_id, account_id, amount, risk_score, timestamp
FROM financial_transactions
WHERE risk_score > 0.8 OR amount > 50000
ORDER BY risk_score DESC, amount DESC;

-- 按渠道统计交易量
SELECT channel, 
       COUNT(*) as transaction_count,
       SUM(amount) as total_amount,
       AVG(amount) as avg_amount
FROM financial_transactions
WHERE status = '成功'
GROUP BY channel;
```

## 数据质量说明

### 数据特点
- **真实性**: 使用Faker库生成符合中国用户习惯的模拟数据
- **完整性**: 所有必填字段都有值，可选字段按业务逻辑设置
- **一致性**: 相关字段之间保持逻辑一致性
- **时效性**: 时间戳覆盖合理的时间范围

### 数据质量问题模拟
为了更好地模拟真实环境，数据集中包含以下质量问题：
- 约5%的异常值和离群点
- 约2%的缺失值（在合理的字段中）
- 约1%的重复记录
- 时间戳的轻微不一致

### 使用建议

1. **学习阶段**：从小型数据集开始，理解数据结构和业务逻辑
2. **练习阶段**：使用中型数据集进行复杂查询和分析练习
3. **性能测试**：使用大型数据集测试查询性能和优化技巧
4. **数据清洗**：练习处理数据质量问题和异常值
5. **实时处理**：将静态数据集转换为流数据进行实时处理练习

## 扩展数据集

如需生成更多数据或自定义数据集，可以使用提供的数据生成器：

```bash
# 生成所有数据集
python scripts/data_generator.py --dataset all

# 生成特定类型的数据集
python scripts/data_generator.py --dataset ecommerce --size 100000 --format csv

# 生成JSON格式的用户行为数据
python scripts/data_generator.py --dataset user_behavior --size 50000 --format json
```

## 注意事项

1. **隐私保护**: 所有数据均为模拟生成，不包含真实个人信息
2. **存储空间**: 大型数据集可能占用较多磁盘空间，请根据需要生成
3. **性能影响**: 处理大型数据集时注意Spark配置和资源分配
4. **版本控制**: 数据集文件较大，建议不要提交到Git仓库

## 技术支持

如果在使用数据集过程中遇到问题，请参考：
- 数据生成器源码：`scripts/data_generator.py`
- 学习教程：`notebooks/` 目录下的相关笔记本
- 故障排除指南：`notebooks/debugging-guide.md`