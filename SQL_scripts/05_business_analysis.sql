-- ============================================================
-- FILE: 05_business_analysis.sql
-- PROJECT: E-Commerce Sales & Customer Analytics
-- PURPOSE: Answer real business questions that drive decisions
-- ============================================================
-- This is where SQL becomes Business Intelligence.
-- Every query here solves a problem a real manager would ask.
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- ANALYSIS 1: REVENUE ANALYSIS
-- ============================================================

-- Q1.1: What is our total revenue, profit, and profit margin?
SELECT
    ROUND(SUM(oi.line_total), 2)                              AS gross_revenue,
    ROUND(SUM(oi.quantity * p.cost_price), 2)                 AS total_cost,
    ROUND(SUM(oi.line_total) - SUM(oi.quantity * p.cost_price), 2) AS gross_profit,
    ROUND(
        (SUM(oi.line_total) - SUM(oi.quantity * p.cost_price))
        / SUM(oi.line_total) * 100,
    1)                                                         AS profit_margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned');
-- INSIGHT: Profit margin benchmark for e-commerce is 10-20%.
-- If ours is below 10%, pricing strategy needs review.

-- Q1.2: Year-over-Year Revenue Comparison (2022 vs 2023)
SELECT
    YEAR(order_date)             AS year,
    ROUND(SUM(total_amount), 0)  AS annual_revenue,
    COUNT(DISTINCT order_id)     AS total_orders,
    ROUND(AVG(total_amount), 0)  AS avg_order_value
FROM orders
WHERE status NOT IN ('Cancelled', 'Returned')
GROUP BY YEAR(order_date)
ORDER BY year;

-- Q1.3: Monthly Revenue with Month-over-Month Growth
-- Using CTE + LAG window function to compute growth %
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m')   AS month,
        ROUND(SUM(total_amount), 0)        AS revenue
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                             AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100,
    1)                                                             AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;
-- WHY LAG: LAG(col) looks at the PREVIOUS row's value.
-- This gives us growth without self-joins or subqueries.
-- BUSINESS USE: Spot which months had revenue drops — investigate why.

-- ============================================================
-- ANALYSIS 2: PRODUCT PERFORMANCE
-- ============================================================

-- Q2.1: Top 10 products by revenue
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)                AS units_sold,
    ROUND(SUM(oi.line_total), 0)    AS revenue,
    ROUND(SUM(oi.line_total)
          - SUM(oi.quantity * p.cost_price), 0) AS profit
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o       ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

-- Q2.2: Category performance with revenue share
WITH category_rev AS (
    SELECT
        p.category,
        ROUND(SUM(oi.line_total), 0) AS category_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o   ON oi.order_id = o.order_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY p.category
)
SELECT
    category,
    category_revenue,
    ROUND(category_revenue * 100.0 / SUM(category_revenue) OVER(), 1) AS revenue_share_pct,
    RANK() OVER (ORDER BY category_revenue DESC)                        AS revenue_rank
FROM category_rev
ORDER BY revenue_rank;
-- WHY RANK(): Shows relative position of each category.
-- REVENUE SHARE: If Electronics is 60%, the business depends heavily on it.

-- Q2.3: Products with high discount but low profit (problem items)
SELECT
    p.product_name,
    p.category,
    ROUND(AVG(oi.discount_percent), 1)                            AS avg_discount_pct,
    ROUND(SUM(oi.line_total), 0)                                  AS revenue,
    ROUND(SUM(oi.line_total) - SUM(oi.quantity * p.cost_price), 0) AS profit,
    ROUND(
        (SUM(oi.line_total) - SUM(oi.quantity * p.cost_price))
        / SUM(oi.line_total) * 100,
    1)                                                             AS margin_pct
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o       ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.product_id, p.product_name, p.category
HAVING avg_discount_pct > 10 AND margin_pct < 15
ORDER BY margin_pct ASC;
-- BUSINESS INSIGHT: Products with high discounts AND low margins are losing money.
-- Recommendation: Reduce discount on these products immediately.

-- ============================================================
-- ANALYSIS 3: CUSTOMER SEGMENTATION (RFM Analysis)
-- ============================================================
-- RFM = Recency + Frequency + Monetary
-- One of the most famous customer analytics frameworks in the world.
-- Used by Amazon, Flipkart, Swiggy, etc.
-- Recency: How recently did the customer order? (lower = better)
-- Frequency: How many orders have they placed? (higher = better)
-- Monetary: How much have they spent total? (higher = better)

WITH rfm_base AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.city,
        DATEDIFF('2024-01-01', MAX(o.order_date))   AS recency_days,
        COUNT(DISTINCT o.order_id)                   AS frequency,
        ROUND(SUM(o.total_amount), 0)                AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY c.customer_id, c.customer_name, c.city
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    customer_name,
    city,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)                    AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
        WHEN r_score <= 2                         THEN 'At Risk'
        ELSE 'Need Attention'
    END                                              AS customer_segment
FROM rfm_scores
ORDER BY rfm_total DESC;
-- WHY NTILE(5): Divides all customers into 5 equal buckets (1=worst, 5=best).
-- Champions = buy often, recently, and spend a lot → highest value customers.
-- At Risk = haven't bought in a long time → send re-engagement emails.

-- Q3.2: Segment summary for business decision-making
WITH rfm_base AS (
    SELECT
        c.customer_id,
        DATEDIFF('2024-01-01', MAX(o.order_date))   AS recency_days,
        COUNT(DISTINCT o.order_id)                   AS frequency,
        ROUND(SUM(o.total_amount), 0)                AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY c.customer_id
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)     AS m_score
    FROM rfm_base
),
segmented AS (
    SELECT *,
        CASE
            WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
            WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
            WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
            WHEN r_score <= 2                         THEN 'At Risk'
            ELSE 'Need Attention'
        END AS segment
    FROM rfm_scores
)
SELECT
    segment,
    COUNT(*)                       AS customer_count,
    ROUND(AVG(recency_days), 0)    AS avg_recency,
    ROUND(AVG(frequency), 1)       AS avg_frequency,
    ROUND(AVG(monetary), 0)        AS avg_spend
FROM segmented
GROUP BY segment
ORDER BY avg_spend DESC;

-- ============================================================
-- ANALYSIS 4: REGIONAL SALES ANALYSIS
-- ============================================================

-- Q4.1: Revenue by state
SELECT
    shipping_state                          AS state,
    COUNT(DISTINCT order_id)                AS orders,
    COUNT(DISTINCT customer_id)             AS unique_customers,
    ROUND(SUM(total_amount), 0)             AS revenue,
    ROUND(AVG(total_amount), 0)             AS avg_order_value
FROM orders
WHERE status NOT IN ('Cancelled', 'Returned')
GROUP BY shipping_state
ORDER BY revenue DESC;

-- Q4.2: State with highest cancellation rate
SELECT
    shipping_state,
    COUNT(*)                                                        AS total_orders,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END)          AS cancelled,
    ROUND(
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                                               AS cancel_rate_pct
FROM orders
GROUP BY shipping_state
ORDER BY cancel_rate_pct DESC;
-- INSIGHT: High cancellation in certain states may indicate
-- logistics issues, payment problems, or fake orders.

-- ============================================================
-- ANALYSIS 5: CUSTOMER RETENTION ANALYSIS
-- ============================================================

-- Q5.1: One-time buyers vs. repeat buyers
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count BETWEEN 2 AND 4 THEN 'Repeat Buyer (2-4 orders)'
        ELSE 'Loyal Buyer (5+ orders)'
    END                        AS buyer_type,
    COUNT(*)                   AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM (
    SELECT customer_id, COUNT(order_id) AS order_count
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY customer_id
) AS order_counts
GROUP BY buyer_type;
-- BUSINESS USE: If 80% are one-time buyers, retention strategy is broken.

-- Q5.2: Monthly cohort retention (new customers who return next month)
-- Which month did each customer first buy?
WITH first_orders AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY customer_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM first_orders
    GROUP BY cohort_month
)
SELECT
    fo.cohort_month,
    cs.cohort_size,
    COUNT(DISTINCT o.customer_id)   AS retained_next_month
FROM first_orders fo
JOIN cohort_sizes cs ON fo.cohort_month = cs.cohort_month
JOIN orders o ON fo.customer_id = o.customer_id
    AND DATE_FORMAT(o.order_date, '%Y-%m') = DATE_FORMAT(
        DATE_ADD(STR_TO_DATE(CONCAT(fo.cohort_month, '-01'), '%Y-%m-%d'),
        INTERVAL 1 MONTH), '%Y-%m')
    AND o.status NOT IN ('Cancelled', 'Returned')
GROUP BY fo.cohort_month, cs.cohort_size
ORDER BY fo.cohort_month;
