# Spark SQL高级查询

本文档介绍Spark SQL的高级查询技术，包括复杂的分析函数、优化技巧和性能调优。

## 1. 高级分析函数

### 1.1 窗口函数

窗口函数允许您在分组数据上执行计算，而不会将结果合并为单个输出行。

```sql
-- 计算每个类别中产品价格的排名
SELECT 
    category,
    product_id,
    price,
    RANK() OVER (PARTITION BY category ORDER BY price DESC) AS price_rank
FROM sales
```

常用窗口函数：

- **排名函数**：`RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`
- **分析函数**：`LAG()`, `LEAD()`, `FIRST_VALUE()`, `LAST_VALUE()`
- **聚合函数**：`SUM()`, `AVG()`, `MIN()`, `MAX()`, `COUNT()`

### 1.2 复杂分组和聚合

```sql
-- 按多个维度分组并计算聚合
SELECT 
    region,
    category,
    SUM(price * quantity) AS total_sales,
    COUNT(DISTINCT customer_id) AS customer_count,
    AVG(price) AS avg_price
FROM sales
GROUP BY region, category
WITH ROLLUP  -- 生成小计和总计
```

### 1.3 透视表和行列转换

```sql
-- 使用PIVOT创建透视表
SELECT *
FROM (
    SELECT region, category, price * quantity AS sales
    FROM sales
) AS source
PIVOT (
    SUM(sales) FOR category IN ('Electronics', 'Clothing', 'Books', 'Home')
) AS pivot_table
```

## 2. 复杂查询模式

### 2.1 递归查询

```sql
-- 使用WITH RECURSIVE计算层次结构（注意：Spark SQL支持有限）
WITH RECURSIVE hierarchy AS (
    -- 基本情况
    SELECT id, parent_id, name, 0 AS level
    FROM categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- 递归情况
    SELECT c.id, c.parent_id, c.name, h.level + 1
    FROM categories c
    JOIN hierarchy h ON c.parent_id = h.id
)
SELECT * FROM hierarchy
```

### 2.2 高级连接技术

```sql
-- 自连接查询
SELECT a.product_id, a.price AS price_a, b.price AS price_b
FROM sales a
JOIN sales b ON a.product_id = b.product_id AND a.date < b.date

-- 半连接
SELECT s.*
FROM sales s
WHERE EXISTS (
    SELECT 1
    FROM customers c
    WHERE s.customer_id = c.customer_id AND c.city = 'Beijing'
)

-- 反连接
SELECT s.*
FROM sales s
WHERE NOT EXISTS (
    SELECT 1
    FROM returns r
    WHERE s.product_id = r.product_id
)
```

### 2.3 集合操作

```sql
-- 使用UNION、INTERSECT和EXCEPT
(SELECT customer_id FROM sales WHERE category = 'Electronics')
UNION
(SELECT customer_id FROM sales WHERE category = 'Books')

(SELECT customer_id FROM sales WHERE category = 'Electronics')
INTERSECT
(SELECT customer_id FROM sales WHERE category = 'Books')

(SELECT customer_id FROM sales WHERE category = 'Electronics')
EXCEPT
(SELECT customer_id FROM sales WHERE category = 'Books')
```

## 3. 高级数据处理

### 3.1 日期和时间处理

```sql
-- 日期提取和操作
SELECT 
    date,
    YEAR(date) AS year,
    MONTH(date) AS month,
    DAY(date) AS day,
    DATEDIFF(CURRENT_DATE, date) AS days_ago,
    DATE_ADD(date, 30) AS date_plus_30
FROM sales
```

### 3.2 字符串处理

```sql
-- 字符串函数
SELECT 
    product_id,
    UPPER(category) AS upper_category,
    LOWER(category) AS lower_category,
    LENGTH(product_id) AS id_length,
    SUBSTRING(product_id, 2, 3) AS id_substring,
    CONCAT(product_id, '-', category) AS product_code
FROM sales
```

### 3.3 JSON处理

```sql
-- JSON操作（假设有一个包含JSON数据的列）
SELECT 
    id,
    GET_JSON_OBJECT(json_data, '$.name') AS name,
    GET_JSON_OBJECT(json_data, '$.address.city') AS city,
    GET_JSON_OBJECT(json_data, '$.items[0].price') AS first_item_price
FROM json_table
```

## 4. 性能优化技巧

### 4.1 查询优化

- **选择合适的分区列**：根据查询模式选择分区列
- **避免数据倾斜**：处理热点键和数据倾斜问题
- **减少shuffle操作**：尽量减少需要数据重分布的操作
- **使用广播连接**：对小表使用广播连接

```sql
-- 使用广播连接提示
SELECT /*+ BROADCAST(c) */ s.*, c.name
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
```

### 4.2 物化视图和缓存

```sql
-- 创建物化视图
CREATE MATERIALIZED VIEW sales_summary AS
SELECT 
    category,
    SUM(price * quantity) AS total_sales
FROM sales
GROUP BY category

-- 缓存表
CACHE TABLE sales
```

### 4.3 分区和分桶

```sql
-- 创建分区表
CREATE TABLE partitioned_sales (
    date STRING,
    product_id STRING,
    category STRING,
    price DOUBLE,
    quantity INT,
    customer_id STRING,
    region STRING
)
PARTITIONED BY (region)
```

## 5. 实际案例：复杂销售数据分析

### 5.1 客户细分分析

```sql
-- 基于购买行为的客户细分
WITH customer_metrics AS (
    SELECT 
        customer_id,
        COUNT(*) AS purchase_count,
        SUM(price * quantity) AS total_spent,
        AVG(price) AS avg_price,
        MAX(date) AS last_purchase_date,
        DATEDIFF(CURRENT_DATE, MAX(date)) AS days_since_last_purchase
    FROM sales
    GROUP BY customer_id
)
SELECT 
    customer_id,
    CASE 
        WHEN total_spent > 1000 AND purchase_count > 5 THEN 'VIP'
        WHEN total_spent > 500 OR purchase_count > 3 THEN '高价值'
        WHEN days_since_last_purchase < 30 THEN '活跃'
        WHEN days_since_last_purchase < 90 THEN '一般'
        ELSE '休眠'
    END AS customer_segment
FROM customer_metrics
```

### 5.2 产品关联分析

```sql
-- 查找经常一起购买的产品
WITH product_pairs AS (
    SELECT 
        a.product_id AS product_a,
        b.product_id AS product_b,
        COUNT(*) AS pair_count
    FROM sales a
    JOIN sales b ON a.customer_id = b.customer_id AND a.date = b.date AND a.product_id < b.product_id
    GROUP BY a.product_id, b.product_id
)
SELECT 
    product_a,
    product_b,
    pair_count,
    RANK() OVER (ORDER BY pair_count DESC) AS pair_rank
FROM product_pairs
WHERE pair_count > 1
ORDER BY pair_count DESC
```

### 5.3 时间序列分析

```sql
-- 销售趋势分析
WITH daily_sales AS (
    SELECT 
        date,
        SUM(price * quantity) AS daily_total
    FROM sales
    GROUP BY date
),
moving_avg AS (
    SELECT 
        date,
        daily_total,
        AVG(daily_total) OVER (
            ORDER BY date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS seven_day_avg
    FROM daily_sales
)
SELECT 
    date,
    daily_total,
    seven_day_avg,
    (daily_total - seven_day_avg) / seven_day_avg * 100 AS percent_diff_from_avg
FROM moving_avg
ORDER BY date
```

## 6. 总结

本文档介绍了Spark SQL的高级查询技术，包括：

1. 高级分析函数（窗口函数、复杂分组和聚合、透视表）
2. 复杂查询模式（递归查询、高级连接技术、集合操作）
3. 高级数据处理（日期和时间处理、字符串处理、JSON处理）
4. 性能优化技巧（查询优化、物化视图和缓存、分区和分桶）
5. 实际案例（客户细分分析、产品关联分析、时间序列分析）

掌握这些高级技术将帮助您更有效地分析大规模数据集，并从中获取有价值的见解。

## 下一步

接下来，我们将学习Spark SQL的性能调优技术。请继续学习 `performance-tuning.md` 文档。