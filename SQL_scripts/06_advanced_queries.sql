-- ============================================================
-- FILE: 06_advanced_queries.sql
-- PROJECT: E-Commerce Sales & Customer Analytics
-- PURPOSE: Showcase advanced SQL — the skills that get you hired
-- ============================================================
-- Advanced SQL = window functions, complex CTEs, views,
-- stored procedures, dynamic calculations, and optimization.
-- These queries separate a junior from a mid/senior analyst.
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- ADVANCED 1: RUNNING TOTALS WITH WINDOW FUNCTIONS
-- ============================================================
-- Running total = cumulative sum as we go through rows chronologically.
-- Used in finance dashboards to show cumulative revenue charts.

SELECT
    DATE_FORMAT(order_date, '%Y-%m')                               AS month,
    ROUND(SUM(total_amount), 0)                                    AS monthly_revenue,
    ROUND(SUM(SUM(total_amount)) OVER (ORDER BY MIN(order_date)), 0) AS cumulative_revenue
FROM orders
WHERE status NOT IN ('Cancelled', 'Returned')
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
-- WHY SUM(SUM(...)): The inner SUM() is the GROUP BY aggregate.
-- The outer SUM() OVER() is the window function running over those group totals.

-- ============================================================
-- ADVANCED 2: CUSTOMER LIFETIME VALUE (CLV)
-- ============================================================
-- CLV = total value a customer brings to the business over their lifetime.
-- One of the most important metrics in e-commerce.

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.city,
        c.registration_date,
        COUNT(DISTINCT o.order_id)                       AS total_orders,
        ROUND(SUM(o.total_amount), 0)                    AS total_spent,
        ROUND(AVG(o.total_amount), 0)                    AS avg_order_value,
        MIN(o.order_date)                                AS first_order_date,
        MAX(o.order_date)                                AS last_order_date,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date))   AS customer_lifespan_days
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY c.customer_id, c.customer_name, c.city, c.registration_date
)
SELECT
    customer_id,
    customer_name,
    city,
    total_orders,
    total_spent,
    avg_order_value,
    customer_lifespan_days,
    DENSE_RANK() OVER (ORDER BY total_spent DESC)          AS value_rank,
    NTILE(4) OVER (ORDER BY total_spent DESC)              AS value_quartile
    -- Quartile 1 = top 25% customers by spending (VIP customers)
FROM customer_metrics
ORDER BY total_spent DESC
LIMIT 20;

-- ============================================================
-- ADVANCED 3: PRODUCT BASKET ANALYSIS (Frequently Bought Together)
-- ============================================================
-- Market Basket Analysis finds product pairs that are often
-- purchased in the same order. Used for "Customers also bought" features.

SELECT
    p1.product_name                          AS product_A,
    p2.product_name                          AS product_B,
    COUNT(*)                                 AS times_bought_together
FROM order_items oi1
JOIN order_items oi2
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id   -- Avoid (A,B) AND (B,A) duplicates
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
LIMIT 15;
-- WHY < instead of !=: Using < ensures each pair appears only once.
-- This is called a SELF JOIN — joining a table to itself.

-- ============================================================
-- ADVANCED 4: MOVING AVERAGE (7-day and 30-day)
-- ============================================================
-- Moving averages smooth out daily spikes to reveal real trends.

WITH daily_sales AS (
    SELECT
        order_date,
        SUM(total_amount)  AS daily_revenue
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY order_date
)
SELECT
    order_date,
    ROUND(daily_revenue, 0)                                        AS daily_revenue,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 0)                                                           AS moving_avg_7d,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 0)                                                           AS moving_avg_30d
FROM daily_sales
ORDER BY order_date;
-- ROWS BETWEEN 6 PRECEDING AND CURRENT ROW = "look at this row and 6 before it"
-- 7 rows total = 7-day moving average.

-- ============================================================
-- ADVANCED 5: VIEWS — Reusable Query Layers
-- ============================================================
-- A VIEW is a saved query that behaves like a virtual table.
-- Instead of writing complex JOINs every time, we create a view once.

CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.order_id,
    o.order_date,
    o.status,
    o.payment_method,
    c.customer_name,
    c.city,
    c.state,
    c.gender,
    c.age,
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    oi.discount_percent,
    oi.sale_price,
    oi.line_total,
    ROUND(oi.line_total - (oi.quantity * p.cost_price), 2)  AS line_profit,
    ROUND(
        (oi.line_total - oi.quantity * p.cost_price)
        / oi.line_total * 100, 1
    )                                                        AS margin_pct
FROM orders o
JOIN customers c   ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p    ON oi.product_id = p.product_id;

-- Now ANY analyst can run simple queries without remembering JOINs:
SELECT * FROM v_order_summary WHERE status = 'Delivered' LIMIT 10;

-- Category revenue from the view (no JOINs needed!):
SELECT category, ROUND(SUM(line_total), 0) AS revenue
FROM v_order_summary
WHERE status NOT IN ('Cancelled', 'Returned')
GROUP BY category ORDER BY revenue DESC;

-- ============================================================
-- ADVANCED 6: STORED PROCEDURE — Parameterized Reports
-- ============================================================
-- A stored procedure is a saved block of SQL code you can CALL like a function.
-- Companies use these for automated reporting — e.g., monthly email reports.

DELIMITER //
CREATE PROCEDURE GetCategoryReport(IN p_category VARCHAR(80))
BEGIN
    SELECT
        p.product_name,
        SUM(oi.quantity)                                     AS units_sold,
        ROUND(SUM(oi.line_total), 0)                         AS revenue,
        ROUND(SUM(oi.line_total) - SUM(oi.quantity * p.cost_price), 0) AS profit,
        ROUND(AVG(oi.discount_percent), 1)                   AS avg_discount
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o       ON oi.order_id  = o.order_id
    WHERE p.category = p_category
      AND o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY p.product_name
    ORDER BY revenue DESC;
END //
DELIMITER ;

-- How to call it (runs report for any category you specify):
CALL GetCategoryReport('Electronics');
CALL GetCategoryReport('Clothing');

-- ============================================================
-- ADVANCED 7: RANK PRODUCTS WITHIN CATEGORY
-- ============================================================
-- RANK() OVER (PARTITION BY ...) = "rank within each group"
-- This is one of the most-asked SQL interview questions.

SELECT
    category,
    product_name,
    ROUND(SUM(oi.line_total), 0)                               AS revenue,
    RANK() OVER (
        PARTITION BY p.category
        ORDER BY SUM(oi.line_total) DESC
    )                                                           AS rank_in_category
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o       ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.category, p.product_name
ORDER BY p.category, rank_in_category;
-- PARTITION BY = "restart ranking for each new category"
-- Without PARTITION BY, RANK() would rank across ALL products globally.

-- ============================================================
-- ADVANCED 8: FIND CUSTOMERS WHO NEVER ORDERED
-- ============================================================
-- Real use case: Send "Come back!" discount coupons to these customers.

SELECT
    c.customer_id,
    c.customer_name,
    c.email,
    c.registration_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.registration_date;
-- LEFT JOIN keeps ALL customers even those without orders.
-- WHERE o.order_id IS NULL filters to only those with NO matching order.
-- This is the standard SQL pattern for "find records with no match".

-- ============================================================
-- ADVANCED 9: PIVOT-STYLE REPORT — Monthly Revenue by Category
-- ============================================================
-- Pivoting = turning rows into columns for easier reading.
-- MySQL doesn't have PIVOT keyword, so we use CASE WHEN + SUM.

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m')                                 AS month,
    ROUND(SUM(CASE WHEN p.category = 'Electronics'   THEN oi.line_total ELSE 0 END), 0) AS Electronics,
    ROUND(SUM(CASE WHEN p.category = 'Clothing'      THEN oi.line_total ELSE 0 END), 0) AS Clothing,
    ROUND(SUM(CASE WHEN p.category = 'Home & Kitchen' THEN oi.line_total ELSE 0 END), 0) AS Home_Kitchen,
    ROUND(SUM(CASE WHEN p.category = 'Books'         THEN oi.line_total ELSE 0 END), 0) AS Books,
    ROUND(SUM(CASE WHEN p.category = 'Sports'        THEN oi.line_total ELSE 0 END), 0) AS Sports,
    ROUND(SUM(oi.line_total), 0)                                        AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;

-- ============================================================
-- ADVANCED 10: QUERY OPTIMIZATION EXAMPLES
-- ============================================================

-- BEFORE optimization (slow — uses subquery in WHERE clause per row):
SELECT customer_id, customer_name
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE total_amount > 50000
);

-- AFTER optimization (faster — JOIN is better than IN for large datasets):
SELECT DISTINCT c.customer_id, c.customer_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.total_amount > 50000;

-- EXPLAIN: Use EXPLAIN to check if indexes are being used:
EXPLAIN SELECT * FROM orders WHERE order_date = '2023-06-15';
-- Look for "Using index" in Extra column — means the query is efficient.
-- If you see "Full table scan", add an index on that column.
