# 推荐系统项目

## 项目概述

本项目演示如何使用Apache Spark构建一个完整的推荐系统，包括协同过滤、基于内容的推荐和混合推荐算法。项目涵盖了从数据预处理到模型部署的完整流程。

## 项目结构

```
recommendation-system/
├── recommendation_system.ipynb    # 主要的Jupyter笔记本
├── recommendation_engine.py       # 推荐系统核心模块
├── README.md                     # 本文档
└── examples/                     # 示例代码和数据
```

## 功能特性

### 1. 多种推荐算法
- **协同过滤 (Collaborative Filtering)**: 基于用户-物品交互矩阵的ALS算法
- **基于内容的推荐 (Content-Based)**: 基于物品特征的相似度推荐
- **混合推荐 (Hybrid)**: 结合多种算法的混合推荐系统

### 2. 完整的数据处理流程
- 隐式反馈数据处理
- 特征工程和编码
- 数据分割和验证

### 3. 系统评估
- RMSE和MAE指标
- Precision@K和Recall@K
- 覆盖率和多样性分析

### 4. 生产就绪功能
- 批量推荐生成
- 实时推荐服务
- 模型保存和加载
- A/B测试框架

## 快速开始

### 1. 环境准备

确保已启动大数据学习环境：

```bash
cd big-data-learning
docker-compose up -d
```

### 2. 运行推荐系统

打开Jupyter Notebook：
- 访问 http://localhost:8888
- 打开 `notebooks/04-projects/recommendation-system/recommendation_system.ipynb`
- 按顺序执行代码单元

### 3. 使用推荐引擎模块

```python
from recommendation_engine import RecommendationService

# 创建推荐服务
rec_service = RecommendationService(spark)

# 训练系统
metrics = rec_service.train_system(user_behavior_df, product_info_df)

# 获取推荐
recommendations = rec_service.get_recommendations("U1001", 5, 'hybrid')

# 评估系统
eval_metrics = rec_service.evaluate_system()
```

## 数据格式

### 用户行为数据

```json
{
  "timestamp": "2023-01-01T10:00:00",
  "user_id": "U1001",
  "action": "view",
  "item_id": "P001",
  "session_id": "S001"
}
```

**字段说明**：
- `timestamp`: 行为发生时间
- `user_id`: 用户标识符
- `action`: 行为类型 (view, add_to_cart, purchase)
- `item_id`: 物品标识符
- `session_id`: 会话标识符

### 产品信息数据

```csv
product_id,category,price
P001,Electronics,599.99
P002,Books,29.99
```

**字段说明**：
- `product_id`: 产品标识符
- `category`: 产品类别
- `price`: 产品价格

## 算法详解

### 1. 协同过滤 (ALS)

使用Spark MLlib的ALS算法实现协同过滤：

```python
als = ALS(
    maxIter=10,
    regParam=0.1,
    userCol="user_id",
    itemCol="item_id",
    ratingCol="rating",
    coldStartStrategy="drop",
    implicitPrefs=True
)
```

**参数说明**：
- `maxIter`: 最大迭代次数
- `regParam`: 正则化参数
- `implicitPrefs`: 是否使用隐式反馈
- `coldStartStrategy`: 冷启动策略

### 2. 基于内容的推荐

基于产品特征计算相似度：

```python
# 特征向量化
feature_assembler = VectorAssembler(
    inputCols=["category_vec", "price_scaled"],
    outputCol="features"
)

# 计算余弦相似度
similarity = cosine_similarity([user_vector], [product_vector])[0][0]
```

### 3. 混合推荐

结合协同过滤和基于内容的推荐：

```python
hybrid_score = cf_score * cf_weight + content_score * content_weight
```

## 评估指标

### 1. 准确性指标

- **RMSE (Root Mean Square Error)**: 预测评分的均方根误差
- **MAE (Mean Absolute Error)**: 预测评分的平均绝对误差

### 2. 排序指标

- **Precision@K**: 前K个推荐中相关物品的比例
- **Recall@K**: 前K个推荐覆盖的相关物品比例
- **F1@K**: Precision和Recall的调和平均

### 3. 系统指标

- **Coverage**: 推荐系统覆盖的物品比例
- **Diversity**: 推荐结果的多样性
- **Novelty**: 推荐结果的新颖性

## 性能优化

### 1. 数据优化

```python
# 数据缓存
ratings_df.cache()

# 数据分区
ratings_df.repartition(8)

# 列式存储
ratings_df.write.parquet("ratings.parquet")
```

### 2. 模型优化

```python
# ALS参数调优
param_grid = {
    'regParam': [0.01, 0.1, 1.0],
    'rank': [10, 50, 100],
    'maxIter': [5, 10, 20]
}

# 交叉验证
cv = CrossValidator(
    estimator=als,
    estimatorParamMaps=param_grid,
    evaluator=evaluator,
    numFolds=3
)
```

### 3. 系统优化

```python
# Spark配置优化
spark = SparkSession.builder \
    .appName("Recommendation System") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .getOrCreate()
```

## 部署策略

### 1. 批量推荐

适用于离线推荐场景：

```python
# 为所有用户生成推荐
batch_recommendations = als_model.recommendForAllUsers(10)

# 保存推荐结果
batch_recommendations.write.mode("overwrite").parquet("recommendations/")
```

### 2. 实时推荐

适用于在线推荐场景：

```python
class RealtimeRecommendationService:
    def __init__(self, model):
        self.model = model
        # 预计算用户和物品特征
        self.user_factors = model.userFactors.collect()
        self.item_factors = model.itemFactors.collect()
    
    def get_recommendations(self, user_id, num_recs=5):
        # 快速推荐生成
        return recommendations
```

### 3. 混合部署

结合批量和实时推荐：

```python
# 批量生成基础推荐
base_recommendations = generate_batch_recommendations()

# 实时调整和个性化
personalized_recs = adjust_recommendations_realtime(base_recommendations, user_context)
```

## A/B测试

### 1. 测试设计

```python
class ABTestFramework:
    def assign_user_to_group(self, user_id, test_name):
        # 用户分组逻辑
        hash_value = hash(user_id) % 2
        return 'A' if hash_value == 0 else 'B'
    
    def record_interaction(self, user_id, group, metric, value):
        # 记录用户交互
        pass
```

### 2. 指标监控

```python
# 监控关键指标
metrics = {
    'click_through_rate': ctr,
    'conversion_rate': cvr,
    'user_engagement': engagement,
    'revenue_per_user': rpu
}
```

## 常见问题和解决方案

### 1. 冷启动问题

**问题**: 新用户或新物品缺乏历史数据

**解决方案**:
- 使用基于内容的推荐
- 利用用户画像和物品特征
- 实施流行度推荐

```python
def handle_cold_start(user_id, user_profile=None):
    if is_new_user(user_id):
        if user_profile:
            return content_based_recommendations(user_profile)
        else:
            return popularity_based_recommendations()
    else:
        return collaborative_filtering_recommendations(user_id)
```

### 2. 数据稀疏性

**问题**: 用户-物品交互矩阵稀疏

**解决方案**:
- 使用隐式反馈数据
- 降维技术 (SVD, NMF)
- 正则化技术

```python
# 使用隐式反馈
als = ALS(implicitPrefs=True, alpha=0.01)

# 正则化
als = ALS(regParam=0.1)
```

### 3. 可扩展性问题

**问题**: 大规模数据处理性能

**解决方案**:
- 分布式计算
- 增量学习
- 近似算法

```python
# 分布式训练
als = ALS(
    checkpointInterval=10,
    intermediateStorageLevel="MEMORY_AND_DISK"
)

# 增量更新
def incremental_update(new_data):
    # 增量更新模型
    pass
```

## 扩展功能

### 1. 深度学习推荐

集成深度学习模型：

```python
# 使用TensorFlow/PyTorch
from pyspark.ml.torch import TorchDistributor

def train_deep_model():
    # 深度学习推荐模型
    pass
```

### 2. 多目标优化

优化多个业务目标：

```python
# 多目标损失函数
def multi_objective_loss(predictions, targets, weights):
    accuracy_loss = mse_loss(predictions, targets)
    diversity_loss = diversity_penalty(predictions)
    return weights[0] * accuracy_loss + weights[1] * diversity_loss
```

### 3. 强化学习

基于用户反馈的在线学习：

```python
class ReinforcementLearningRecommender:
    def update_policy(self, user_feedback):
        # 根据用户反馈更新推荐策略
        pass
```

## 最佳实践

### 1. 数据质量

- 数据清洗和预处理
- 异常值检测和处理
- 数据一致性检查

### 2. 模型选择

- 根据业务场景选择合适算法
- 考虑计算资源和延迟要求
- 平衡准确性和多样性

### 3. 系统监控

- 实时性能监控
- 推荐质量跟踪
- 用户满意度调研

### 4. 持续优化

- 定期模型重训练
- A/B测试验证改进
- 用户反馈收集和分析

## 参考资源

- [Apache Spark MLlib文档](https://spark.apache.org/docs/latest/ml-guide.html)
- [推荐系统实践](https://github.com/microsoft/recommenders)
- [协同过滤算法详解](https://spark.apache.org/docs/latest/ml-collaborative-filtering.html)
- [推荐系统评估指标](https://en.wikipedia.org/wiki/Evaluation_measures_(information_retrieval))

## 联系支持

如有问题或建议，请通过以下方式联系：

- 项目Issues: [GitHub Issues](https://github.com/your-repo/issues)
- 邮件支持: support@example.com
- 技术文档: [项目Wiki](https://github.com/your-repo/wiki)