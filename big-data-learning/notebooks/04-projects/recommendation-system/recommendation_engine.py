"""
推荐系统引擎模块

这个模块提供了完整的推荐系统实现，包括协同过滤、基于内容的推荐和混合推荐算法。
"""

import numpy as np
from typing import Dict, List, Tuple, Optional
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.functions import *
from pyspark.sql.types import *
from pyspark.ml.recommendation import ALS
from pyspark.ml.feature import StringIndexer, VectorAssembler, OneHotEncoder, StandardScaler
from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.ml import Pipeline
from sklearn.metrics.pairwise import cosine_similarity

class DataPreprocessor:
    """数据预处理器"""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
    
    def generate_implicit_ratings(self, user_behavior_df: DataFrame) -> DataFrame:
        """
        根据用户行为生成隐式评分
        view: 1分, add_to_cart: 3分, purchase: 5分
        """
        rating_expr = when(col("action") == "view", 1.0) \
                     .when(col("action") == "add_to_cart", 3.0) \
                     .when(col("action") == "purchase", 5.0) \
                     .otherwise(0.0)
        
        ratings_df = user_behavior_df.withColumn("rating", rating_expr) \
                                   .filter(col("rating") > 0) \
                                   .groupBy("user_id", "item_id") \
                                   .agg(max("rating").alias("rating")) \
                                   .withColumnRenamed("item_id", "product_id")
        
        return ratings_df
    
    def encode_ids(self, ratings_df: DataFrame) -> Tuple[DataFrame, Dict]:
        """
        将字符串ID编码为数值ID
        """
        # 用户ID编码
        user_indexer = StringIndexer(inputCol="user_id", outputCol="user_index")
        user_indexer_model = user_indexer.fit(ratings_df)
        ratings_indexed = user_indexer_model.transform(ratings_df)
        
        # 产品ID编码
        item_indexer = StringIndexer(inputCol="product_id", outputCol="item_index")
        item_indexer_model = item_indexer.fit(ratings_indexed)
        ratings_indexed = item_indexer_model.transform(ratings_indexed)
        
        # 转换为整数类型
        ratings_final = ratings_indexed.select(
            col("user_index").cast("int").alias("user_id"),
            col("item_index").cast("int").alias("item_id"),
            col("rating").cast("float")
        )
        
        indexers = {
            'user_indexer': user_indexer_model,
            'item_indexer': item_indexer_model
        }
        
        return ratings_final, indexers
    
    def prepare_product_features(self, product_info_df: DataFrame) -> Tuple[DataFrame, Pipeline]:
        """
        准备产品特征向量
        """
        # 类别编码
        category_indexer = StringIndexer(inputCol="category", outputCol="category_index")
        category_encoder = OneHotEncoder(inputCol="category_index", outputCol="category_vec")
        
        # 价格标准化
        price_assembler = VectorAssembler(inputCols=["price"], outputCol="price_vec")
        price_scaler = StandardScaler(inputCol="price_vec", outputCol="price_scaled")
        
        # 特征组合
        feature_assembler = VectorAssembler(
            inputCols=["category_vec", "price_scaled"],
            outputCol="features"
        )
        
        # 构建特征处理管道
        feature_pipeline = Pipeline(stages=[
            category_indexer,
            category_encoder,
            price_assembler,
            price_scaler,
            feature_assembler
        ])
        
        # 训练特征处理管道
        feature_model = feature_pipeline.fit(product_info_df)
        product_features = feature_model.transform(product_info_df)
        
        return product_features, feature_model

class CollaborativeFilteringRecommender:
    """协同过滤推荐器"""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.model = None
        self.indexers = None
    
    def train(self, ratings_df: DataFrame, **als_params) -> Dict:
        """
        训练ALS协同过滤模型
        """
        # 数据分割
        training_data, test_data = ratings_df.randomSplit([0.8, 0.2], seed=42)
        
        # 默认ALS参数
        default_params = {
            'maxIter': 10,
            'regParam': 0.1,
            'userCol': 'user_id',
            'itemCol': 'item_id',
            'ratingCol': 'rating',
            'coldStartStrategy': 'drop',
            'implicitPrefs': True,
            'seed': 42
        }
        default_params.update(als_params)
        
        # 构建和训练ALS模型
        als = ALS(**default_params)
        self.model = als.fit(training_data)
        
        # 模型评估
        predictions = self.model.transform(test_data)
        valid_predictions = predictions.filter(col("prediction").isNotNull())
        
        evaluator = RegressionEvaluator(
            metricName="rmse",
            labelCol="rating",
            predictionCol="prediction"
        )
        rmse = evaluator.evaluate(valid_predictions)
        
        evaluator_mae = RegressionEvaluator(
            metricName="mae",
            labelCol="rating",
            predictionCol="prediction"
        )
        mae = evaluator_mae.evaluate(valid_predictions)
        
        return {
            'rmse': rmse,
            'mae': mae,
            'training_size': training_data.count(),
            'test_size': test_data.count()
        }
    
    def recommend_for_user(self, user_id: int, num_recommendations: int = 5) -> DataFrame:
        """
        为指定用户生成推荐
        """
        if self.model is None:
            raise ValueError("模型尚未训练")
        
        user_df = self.spark.createDataFrame([(user_id,)], ["user_id"])
        recommendations = self.model.recommendForUserSubset(user_df, num_recommendations)
        
        return recommendations
    
    def recommend_for_all_users(self, num_recommendations: int = 5) -> DataFrame:
        """
        为所有用户生成推荐
        """
        if self.model is None:
            raise ValueError("模型尚未训练")
        
        return self.model.recommendForAllUsers(num_recommendations)
    
    def get_similar_items(self, item_id: int, num_similar: int = 5) -> DataFrame:
        """
        获取相似物品
        """
        if self.model is None:
            raise ValueError("模型尚未训练")
        
        item_df = self.spark.createDataFrame([(item_id,)], ["item_id"])
        similar_items = self.model.recommendForItemSubset(item_df, num_similar)
        
        return similar_items

class ContentBasedRecommender:
    """基于内容的推荐器"""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.product_features = None
    
    def fit(self, product_features_df: DataFrame):
        """
        训练基于内容的推荐器
        """
        self.product_features = product_features_df
    
    def recommend_for_user(self, user_id: str, user_ratings: DataFrame, 
                          num_recommendations: int = 5) -> List[Tuple]:
        """
        为用户生成基于内容的推荐
        """
        if self.product_features is None:
            raise ValueError("推荐器尚未训练")
        
        # 获取用户已评分的产品
        user_items = user_ratings.filter(col("user_id") == user_id).select("product_id", "rating")
        
        if user_items.count() == 0:
            return []
        
        # 计算用户偏好向量
        user_profile = user_items.join(self.product_features, "product_id") \
                                .select("rating", "features")
        
        # 转换为Pandas进行计算
        user_profile_pd = user_profile.toPandas()
        product_features_pd = self.product_features.toPandas()
        
        if len(user_profile_pd) == 0:
            return []
        
        # 计算用户偏好向量（加权平均）
        user_vector = np.zeros(len(user_profile_pd.iloc[0]['features']))
        total_rating = 0
        
        for _, row in user_profile_pd.iterrows():
            rating = row['rating']
            features = np.array(row['features'])
            user_vector += rating * features
            total_rating += rating
        
        if total_rating > 0:
            user_vector /= total_rating
        
        # 计算与所有产品的相似度
        similarities = []
        rated_products = set(user_profile_pd.get('product_id', []))
        
        for _, product in product_features_pd.iterrows():
            if product['product_id'] not in rated_products:
                product_vector = np.array(product['features'])
                similarity = cosine_similarity([user_vector], [product_vector])[0][0]
                similarities.append((product['product_id'], similarity))
        
        # 排序并返回Top-N
        similarities.sort(key=lambda x: x[1], reverse=True)
        return similarities[:num_recommendations]

class HybridRecommendationSystem:
    """混合推荐系统"""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.cf_recommender = CollaborativeFilteringRecommender(spark)
        self.content_recommender = ContentBasedRecommender(spark)
        self.indexers = None
    
    def train(self, ratings_df: DataFrame, product_features_df: DataFrame, 
              indexers: Dict, **als_params) -> Dict:
        """
        训练混合推荐系统
        """
        self.indexers = indexers
        
        # 训练协同过滤模型
        cf_metrics = self.cf_recommender.train(ratings_df, **als_params)
        
        # 训练基于内容的推荐器
        self.content_recommender.fit(product_features_df)
        
        return cf_metrics
    
    def get_hybrid_recommendations(self, user_id: str, original_ratings: DataFrame,
                                 num_recommendations: int = 5, 
                                 cf_weight: float = 0.7, 
                                 content_weight: float = 0.3) -> List[Tuple]:
        """
        生成混合推荐
        """
        recommendations = []
        
        try:
            # 获取用户索引
            user_df = self.spark.createDataFrame([(user_id,)], ["user_id"])
            user_indexed = self.indexers['user_indexer'].transform(user_df)
            user_index = user_indexed.select("user_index").collect()[0][0]
            
            # 获取协同过滤推荐
            cf_recs = self.cf_recommender.recommend_for_user(int(user_index), num_recommendations * 2)
            
            if cf_recs.count() > 0:
                cf_items = cf_recs.select("recommendations").collect()[0][0]
                cf_scores = {item.item_id: item.rating * cf_weight for item in cf_items}
                
                # 获取基于内容的推荐
                content_recs = self.content_recommender.recommend_for_user(
                    user_id, original_ratings, num_recommendations * 2
                )
                content_scores = {item_id: score * content_weight for item_id, score in content_recs}
                
                # 合并推荐结果
                all_items = set(cf_scores.keys()) | set(content_scores.keys())
                hybrid_scores = {}
                
                for item in all_items:
                    cf_score = cf_scores.get(item, 0)
                    content_score = content_scores.get(item, 0)
                    hybrid_scores[item] = cf_score + content_score
                
                # 排序并返回Top-N
                sorted_items = sorted(hybrid_scores.items(), key=lambda x: x[1], reverse=True)
                recommendations = sorted_items[:num_recommendations]
        
        except Exception as e:
            print(f"推荐生成错误: {e}")
            return []
        
        return recommendations

class RecommendationEvaluator:
    """推荐系统评估器"""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
    
    def precision_at_k(self, recommendations: List, ground_truth: List, k: int = 5) -> float:
        """
        计算Precision@K
        """
        if not recommendations or not ground_truth:
            return 0.0
        
        top_k_recs = recommendations[:k]
        relevant_items = set(ground_truth)
        recommended_items = set(top_k_recs)
        
        intersection = recommended_items & relevant_items
        return len(intersection) / len(recommended_items) if recommended_items else 0.0
    
    def recall_at_k(self, recommendations: List, ground_truth: List, k: int = 5) -> float:
        """
        计算Recall@K
        """
        if not recommendations or not ground_truth:
            return 0.0
        
        top_k_recs = recommendations[:k]
        relevant_items = set(ground_truth)
        recommended_items = set(top_k_recs)
        
        intersection = recommended_items & relevant_items
        return len(intersection) / len(relevant_items) if relevant_items else 0.0
    
    def coverage(self, all_recommendations: DataFrame, total_items: int) -> float:
        """
        计算推荐覆盖率
        """
        recommended_items = all_recommendations.select("item_id").distinct().count()
        return recommended_items / total_items if total_items > 0 else 0.0
    
    def diversity(self, recommendations: List, item_features: Dict) -> float:
        """
        计算推荐多样性
        """
        if len(recommendations) < 2:
            return 0.0
        
        total_distance = 0
        count = 0
        
        for i in range(len(recommendations)):
            for j in range(i + 1, len(recommendations)):
                item1, item2 = recommendations[i], recommendations[j]
                if item1 in item_features and item2 in item_features:
                    # 计算特征向量之间的距离
                    features1 = np.array(item_features[item1])
                    features2 = np.array(item_features[item2])
                    distance = np.linalg.norm(features1 - features2)
                    total_distance += distance
                    count += 1
        
        return total_distance / count if count > 0 else 0.0

class RecommendationService:
    """推荐服务类"""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.hybrid_system = HybridRecommendationSystem(spark)
        self.preprocessor = DataPreprocessor(spark)
        self.evaluator = RecommendationEvaluator(spark)
        self.is_trained = False
    
    def train_system(self, user_behavior_df: DataFrame, product_info_df: DataFrame, 
                    **training_params) -> Dict:
        """
        训练完整的推荐系统
        """
        print("开始训练推荐系统...")
        
        # 数据预处理
        print("1. 数据预处理...")
        ratings_df = self.preprocessor.generate_implicit_ratings(user_behavior_df)
        ratings_encoded, indexers = self.preprocessor.encode_ids(ratings_df)
        product_features, feature_model = self.preprocessor.prepare_product_features(product_info_df)
        
        # 训练混合推荐系统
        print("2. 训练推荐模型...")
        metrics = self.hybrid_system.train(ratings_encoded, product_features, indexers, **training_params)
        
        # 保存必要的数据
        self.ratings_df = ratings_df
        self.product_features = product_features
        self.indexers = indexers
        self.feature_model = feature_model
        self.is_trained = True
        
        print("推荐系统训练完成!")
        return metrics
    
    def get_recommendations(self, user_id: str, num_recommendations: int = 5, 
                          recommendation_type: str = 'hybrid') -> List[Tuple]:
        """
        获取用户推荐
        """
        if not self.is_trained:
            raise ValueError("推荐系统尚未训练")
        
        if recommendation_type == 'collaborative':
            # 协同过滤推荐
            user_df = self.spark.createDataFrame([(user_id,)], ["user_id"])
            user_indexed = self.indexers['user_indexer'].transform(user_df)
            user_index = user_indexed.select("user_index").collect()[0][0]
            
            cf_recs = self.hybrid_system.cf_recommender.recommend_for_user(
                int(user_index), num_recommendations
            )
            
            if cf_recs.count() > 0:
                items = cf_recs.select("recommendations").collect()[0][0]
                return [(item.item_id, item.rating) for item in items]
            else:
                return []
        
        elif recommendation_type == 'content':
            # 基于内容的推荐
            return self.hybrid_system.content_recommender.recommend_for_user(
                user_id, self.ratings_df, num_recommendations
            )
        
        elif recommendation_type == 'hybrid':
            # 混合推荐
            return self.hybrid_system.get_hybrid_recommendations(
                user_id, self.ratings_df, num_recommendations
            )
        
        else:
            raise ValueError(f"不支持的推荐类型: {recommendation_type}")
    
    def evaluate_system(self, test_users: List[str] = None) -> Dict:
        """
        评估推荐系统性能
        """
        if not self.is_trained:
            raise ValueError("推荐系统尚未训练")
        
        if test_users is None:
            # 随机选择一些用户进行测试
            all_users = self.ratings_df.select("user_id").distinct().collect()
            test_users = [row.user_id for row in all_users[:min(10, len(all_users))]]
        
        total_precision = 0
        total_recall = 0
        total_users = len(test_users)
        
        for user_id in test_users:
            try:
                # 获取推荐
                recommendations = self.get_recommendations(user_id, 5, 'hybrid')
                
                # 获取用户的真实偏好（高评分物品）
                user_items = self.ratings_df.filter(
                    (col("user_id") == user_id) & (col("rating") >= 4.0)
                ).select("product_id").collect()
                ground_truth = [row.product_id for row in user_items]
                
                # 计算指标
                rec_items = [item_id for item_id, _ in recommendations]
                precision = self.evaluator.precision_at_k(rec_items, ground_truth, 5)
                recall = self.evaluator.recall_at_k(rec_items, ground_truth, 5)
                
                total_precision += precision
                total_recall += recall
                
            except Exception as e:
                print(f"评估用户 {user_id} 时出错: {e}")
                total_users -= 1
        
        avg_precision = total_precision / total_users if total_users > 0 else 0
        avg_recall = total_recall / total_users if total_users > 0 else 0
        f1_score = 2 * avg_precision * avg_recall / (avg_precision + avg_recall) if (avg_precision + avg_recall) > 0 else 0
        
        return {
            'precision@5': avg_precision,
            'recall@5': avg_recall,
            'f1@5': f1_score,
            'evaluated_users': total_users
        }
    
    def save_model(self, model_path: str):
        """
        保存训练好的模型
        """
        if not self.is_trained:
            raise ValueError("推荐系统尚未训练")
        
        import os
        os.makedirs(model_path, exist_ok=True)
        
        # 保存ALS模型
        self.hybrid_system.cf_recommender.model.write().overwrite().save(f"{model_path}/als_model")
        
        # 保存索引器
        self.indexers['user_indexer'].write().overwrite().save(f"{model_path}/user_indexer")
        self.indexers['item_indexer'].write().overwrite().save(f"{model_path}/item_indexer")
        
        # 保存特征处理模型
        self.feature_model.write().overwrite().save(f"{model_path}/feature_model")
        
        print(f"模型已保存到: {model_path}")

# 使用示例
if __name__ == "__main__":
    # 创建SparkSession
    spark = SparkSession.builder.appName("Recommendation System").getOrCreate()
    
    # 创建推荐服务
    rec_service = RecommendationService(spark)
    
    # 加载数据（示例）
    user_behavior_df = spark.read.json("/home/jovyan/data/sample/user_behavior.json")
    product_info_df = spark.read.option("header", "true").option("inferSchema", "true").csv("/home/jovyan/data/sample/sales_data.csv")
    product_info_df = product_info_df.select("product_id", "category", "price").distinct()
    
    # 训练系统
    metrics = rec_service.train_system(user_behavior_df, product_info_df)
    print("训练指标:", metrics)
    
    # 获取推荐
    recommendations = rec_service.get_recommendations("U1001", 5, 'hybrid')
    print("推荐结果:", recommendations)
    
    # 评估系统
    eval_metrics = rec_service.evaluate_system()
    print("评估指标:", eval_metrics)
    
    # 保存模型
    rec_service.save_model("/home/jovyan/models/recommendation_system")
    
    spark.stop()