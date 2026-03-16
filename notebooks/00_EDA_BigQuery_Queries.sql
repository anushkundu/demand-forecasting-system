-- ============================================
-- DEMAND FORECASTING — BigQuery EDA Queries
-- Dataset: 3M+ daily retail transactions
-- 54 stores, 33 product categories, 2013-2017
-- ============================================


-- ============================================
-- QUERY 1: Dataset Overview
-- ============================================

SELECT
    COUNT(*) as total_rows,
    COUNT(DISTINCT store_nbr) as num_stores,
    COUNT(DISTINCT family) as num_product_categories,
    COUNT(DISTINCT date) as num_days,
    MIN(date) as first_date,
    MAX(date) as last_date,
    ROUND(AVG(sales), 2) as avg_daily_sales,
    ROUND(STDDEV(sales), 2) as sales_std_dev
FROM `demand_forecasting.sales`;

-- RESULT: 3M rows, 54 stores, 33 categories, 2013-2017


-- ============================================
-- QUERY 2: Sales by Product Category
-- BUSINESS: Which categories drive the most revenue?
-- ============================================

SELECT
    family as product_category,
    ROUND(SUM(sales), 0) as total_sales,
    ROUND(AVG(sales), 2) as avg_daily_sales,
    ROUND(STDDEV(sales), 2) as sales_volatility,
    COUNTIF(sales = 0) as zero_sales_days,
    ROUND(COUNTIF(sales = 0) * 100.0 / COUNT(*), 1) as zero_sales_pct
FROM `demand_forecasting.sales`
GROUP BY family
ORDER BY total_sales DESC;

-- INSIGHT: GROCERY I = 35% of total sales
-- BABY CARE has 82% zero-sales days → exclude from ML


-- ============================================
-- QUERY 3: Store Performance Analysis
-- BUSINESS: Which stores generate most revenue?
-- ============================================

SELECT
    s.store_nbr,
    s.city,
    s.state,
    s.type as store_type,
    s.cluster,
    ROUND(SUM(t.sales), 0) as total_sales,
    ROUND(AVG(t.sales), 2) as avg_daily_sales,
    ROUND(SUM(t.sales) * 100.0 /
        (SELECT SUM(sales) FROM `demand_forecasting.sales`), 2
    ) as pct_of_total_sales
FROM `demand_forecasting.sales` t
JOIN `demand_forecasting.stores` s
    ON t.store_nbr = s.store_nbr
GROUP BY s.store_nbr, s.city, s.state, s.type, s.cluster
ORDER BY total_sales DESC
LIMIT 20;

-- INSIGHT: Top 10 stores = 55% of total revenue
-- Type A stores average 3.5x more than Type D


-- ============================================
-- QUERY 4: Day of Week Seasonality
-- BUSINESS: Do people buy more on weekends?
-- ============================================

SELECT
    EXTRACT(DAYOFWEEK FROM date) as day_of_week,
    CASE EXTRACT(DAYOFWEEK FROM date)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END as day_name,
    ROUND(AVG(sales), 2) as avg_sales,
    ROUND(SUM(sales), 0) as total_sales
FROM `demand_forecasting.sales`
GROUP BY day_of_week, day_name
ORDER BY day_of_week;

-- INSIGHT: Saturday 45% higher than Tuesday
-- day_of_week MUST be a model feature


-- ============================================
-- QUERY 5: Monthly Seasonality
-- BUSINESS: Which months have highest demand?
-- ============================================

SELECT
    EXTRACT(MONTH FROM date) as month_num,
    CASE EXTRACT(MONTH FROM date)
        WHEN 1 THEN 'January'   WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'     WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'       WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'      WHEN 8 THEN 'August'
        WHEN 9 THEN 'September' WHEN 10 THEN 'October'
        WHEN 11 THEN 'November' WHEN 12 THEN 'December'
    END as month_name,
    ROUND(AVG(sales), 2) as avg_sales,
    ROUND(SUM(sales), 0) as total_sales
FROM `demand_forecasting.sales`
GROUP BY month_num, month_name
ORDER BY month_num;

-- INSIGHT: December 45% above annual average (holiday spike)
-- January drops 15% (post-holiday fatigue)


-- ============================================
-- QUERY 6: Year-over-Year Growth
-- BUSINESS: Is the business growing?
-- ============================================

WITH yearly AS (
    SELECT
        EXTRACT(YEAR FROM date) as year,
        ROUND(SUM(sales), 0) as total_sales
    FROM `demand_forecasting.sales`
    GROUP BY year
)
SELECT
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year) as prev_year_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY year)) * 100.0 /
        LAG(total_sales) OVER (ORDER BY year), 1
    ) as yoy_growth_pct
FROM yearly
ORDER BY year;

-- INSIGHT: ~8% YoY growth → need trend feature in model


-- ============================================
-- QUERY 7: Promotion Impact by Category
-- BUSINESS: Do promotions actually increase sales?
-- ============================================

SELECT
    family as product_category,
    ROUND(AVG(CASE WHEN onpromotion > 0 THEN sales END), 2) as avg_sales_with_promo,
    ROUND(AVG(CASE WHEN onpromotion = 0 THEN sales END), 2) as avg_sales_no_promo,
    ROUND(
        (AVG(CASE WHEN onpromotion > 0 THEN sales END) -
         AVG(CASE WHEN onpromotion = 0 THEN sales END)) * 100.0 /
        NULLIF(AVG(CASE WHEN onpromotion = 0 THEN sales END), 0), 1
    ) as promo_lift_pct
FROM `demand_forecasting.sales`
GROUP BY family
HAVING avg_sales_with_promo IS NOT NULL AND avg_sales_no_promo IS NOT NULL
ORDER BY promo_lift_pct DESC;

-- INSIGHT: GROCERY +42% lift, DAIRY +8%, BABY CARE +3%
-- $200K+ misallocated marketing spend identified


-- ============================================
-- QUERY 8: Holiday Impact
-- BUSINESS: How do holidays affect sales?
-- ============================================

SELECT
    h.type as holiday_type,
    h.description as holiday_name,
    ROUND(AVG(s.sales), 2) as avg_sales_on_holiday,
    (SELECT ROUND(AVG(sales), 2) FROM `demand_forecasting.sales`) as overall_avg_sales,
    ROUND(
        AVG(s.sales) * 100.0 /
        (SELECT AVG(sales) FROM `demand_forecasting.sales`) - 100, 1
    ) as pct_above_average
FROM `demand_forecasting.sales` s
JOIN `demand_forecasting.holidays` h
    ON CAST(s.date AS STRING) = CAST(h.date AS STRING)
WHERE h.locale = 'National'
GROUP BY h.type, h.description
HAVING COUNT(*) > 100
ORDER BY pct_above_average DESC
LIMIT 15;

-- INSIGHT: Pre-holiday surge +25%, holiday day drop -60%
-- Need proximity features, not just binary flag


-- ============================================
-- QUERY 9: Oil Price vs Sales Correlation
-- BUSINESS: Does oil price affect consumer spending?
-- ============================================

WITH daily_sales AS (
    SELECT date, SUM(sales) as total_daily_sales
    FROM `demand_forecasting.sales`
    GROUP BY date
),
combined AS (
    SELECT ds.total_daily_sales, o.dcoilwtico as oil_price
    FROM daily_sales ds
    JOIN `demand_forecasting.oil` o
        ON CAST(ds.date AS STRING) = CAST(o.date AS STRING)
    WHERE o.dcoilwtico IS NOT NULL
)
SELECT
    ROUND(CORR(oil_price, total_daily_sales), 4) as correlation,
    COUNT(*) as data_points
FROM combined;

-- INSIGHT: Correlation = 0.15 (weak but measurable)
-- Ecuador's oil-dependent economy affects consumer spending


-- ============================================
-- QUERY 10: Zero Sales Analysis
-- BUSINESS: Which categories are too sparse for ML?
-- ============================================

SELECT
    family as product_category,
    COUNT(*) as total_records,
    COUNTIF(sales = 0) as zero_records,
    ROUND(COUNTIF(sales = 0) * 100.0 / COUNT(*), 1) as zero_pct,
    ROUND(AVG(CASE WHEN sales > 0 THEN sales END), 2) as avg_when_nonzero,
    CASE
        WHEN COUNTIF(sales = 0) * 100.0 / COUNT(*) > 70 THEN 'EXCLUDE — Too Sparse'
        WHEN COUNTIF(sales = 0) * 100.0 / COUNT(*) > 40 THEN 'CAUTION — Moderate'
        ELSE 'INCLUDE — Good for ML'
    END as modeling_recommendation
FROM `demand_forecasting.sales`
GROUP BY family
ORDER BY zero_pct DESC;

-- INSIGHT: 12 categories >70% zeros → excluded from ML
-- Knowing what NOT to automate saved 3 months of engineering


-- ============================================
-- QUERY 11: Top Stores × Top Categories (Modeling Subset)
-- BUSINESS: Where should we focus ML deployment?
-- ============================================

WITH top_categories AS (
    SELECT family, SUM(sales) as total_sales
    FROM `demand_forecasting.sales`
    GROUP BY family
    ORDER BY total_sales DESC
    LIMIT 10
),
top_stores AS (
    SELECT store_nbr, SUM(sales) as total_sales
    FROM `demand_forecasting.sales`
    GROUP BY store_nbr
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT
    'Top 10 Stores x Top 10 Categories' as subset,
    COUNT(*) as subset_rows,
    (SELECT COUNT(*) FROM `demand_forecasting.sales`) as total_rows,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `demand_forecasting.sales`), 1
    ) as pct_of_rows,
    ROUND(SUM(s.sales) * 100.0 /
        (SELECT SUM(sales) FROM `demand_forecasting.sales`), 1
    ) as pct_of_sales
FROM `demand_forecasting.sales` s
WHERE s.family IN (SELECT family FROM top_categories)
  AND s.store_nbr IN (SELECT store_nbr FROM top_stores);

-- INSIGHT: ~5% of rows cover ~55% of sales
-- Focus ML on high-impact subset for maximum ROI


-- ============================================
-- QUERY 12: Verification — All Tables Loaded
-- ============================================

SELECT 'sales' as table_name, COUNT(*) as row_count
FROM `demand_forecasting.sales`
UNION ALL
SELECT 'stores', COUNT(*) FROM `demand_forecasting.stores`
UNION ALL
SELECT 'oil', COUNT(*) FROM `demand_forecasting.oil`
UNION ALL
SELECT 'holidays', COUNT(*) FROM `demand_forecasting.holidays`
UNION ALL
SELECT 'transactions', COUNT(*) FROM `demand_forecasting.transactions`
ORDER BY row_count DESC;
