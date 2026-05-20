-- ============================================================
-- FILE: 04_exploratory_analysis.sql
-- PROJECT: E-Commerce Sales & Customer Analytics
-- PURPOSE: Understand the dataset before deeper business analysis
-- ============================================================
-- EDA (Exploratory Data Analysis) answers:
--   "What does this data actually look like?"
-- We check counts, ranges, distributions, and trends.
-- These findings guide WHICH business questions to ask next.
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- SECTION 1: DATASET OVERVIEW
-- ============================================================

-- 1.1 Overall row counts
SELECT 'customers'  AS entity, COUNT(*) AS total FROM customers
UNION ALL
SELECT 'products',               COUNT(*)         FROM products
UNION ALL
SELECT 'orders',                 COUNT(*)         FROM orders
UNION ALL
SELECT 'order_items',            COUNT(*)         FROM order_items;

-- 1.2 Date range of orders — what time period does our data cover?
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS days_of_data
FROM orders;
-- WHY: Confirms our data covers Jan 2022 – Dec 2023 (2 full years).
-- We can do Year-over-Year comparisons and monthly trends.

-- 1.3 Order status distribution — how many orders are in each state?
SELECT
    status,
    COUNT(*)                                       AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM orders
GROUP BY status
ORDER BY order_count DESC;
-- WHY: If "Cancelled" is very high, that's a business problem.
-- Window function SUM() OVER() gives total without a subquery.

-- ============================================================
-- SECTION 2: CUSTOMER DEMOGRAPHICS
-- ============================================================

-- 2.1 How many customers per state?
SELECT
    state,
    COUNT(DISTINCT customer_id) AS customer_count
FROM customers
GROUP BY state
ORDER BY customer_count DESC;

-- 2.2 Gender distribution
SELECT
    gender,
    COUNT(*)                                              AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 1) AS pct
FROM customers
GROUP BY gender;

-- 2.3 Age group distribution using CASE WHEN
-- CASE WHEN = SQL's if-else statement
SELECT
    CASE
        WHEN age BETWEEN 18 AND 24 THEN '18-24 (Gen Z)'
        WHEN age BETWEEN 25 AND 34 THEN '25-34 (Millennials)'
        WHEN age BETWEEN 35 AND 44 THEN '35-44 (Gen X)'
        WHEN age BETWEEN 45 AND 54 THEN '45-54 (Older Gen X)'
        ELSE '55+ (Boomers)'
    END                                        AS age_group,
    COUNT(*)                                   AS customer_count,
    ROUND(AVG(age), 1)                         AS avg_age
FROM customers
GROUP BY age_group
ORDER BY MIN(age);
-- WHY: Age segmentation tells marketing which age group to target.

-- 2.4 Customer registration trend by month
-- DATE_FORMAT converts a DATE into a readable string
SELECT
    DATE_FORMAT(registration_date, '%Y-%m') AS reg_month,
    COUNT(*)                                AS new_customers
FROM customers
WHERE registration_date IS NOT NULL
GROUP BY reg_month
ORDER BY reg_month;

-- ============================================================
-- SECTION 3: PRODUCT & CATEGORY OVERVIEW
-- ============================================================

-- 3.1 Products per category
SELECT
    category,
    COUNT(*) AS product_count,
    MIN(unit_price) AS cheapest,
    MAX(unit_price) AS most_expensive,
    ROUND(AVG(unit_price), 0) AS avg_price
FROM products
GROUP BY category
ORDER BY avg_price DESC;

-- 3.2 Profit margin per category
-- Profit Margin % = (price - cost) / price × 100
SELECT
    category,
    ROUND(AVG((unit_price - cost_price) / unit_price * 100), 1) AS avg_margin_pct
FROM products
GROUP BY category
ORDER BY avg_margin_pct DESC;

-- ============================================================
-- SECTION 4: SALES VOLUME OVERVIEW
-- ============================================================

-- 4.1 Total revenue, orders, and average order value
SELECT
    COUNT(DISTINCT o.order_id)          AS total_orders,
    COUNT(DISTINCT o.customer_id)       AS customers_who_ordered,
    SUM(oi.line_total)                  AS gross_revenue,
    ROUND(AVG(o.total_amount), 2)       AS avg_order_value,
    SUM(oi.quantity)                    AS units_sold
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned');
-- WHY NOT IN: We exclude cancelled/returned orders from revenue.
-- Including them would overstate revenue — a common mistake.

-- 4.2 Monthly order volume trend
SELECT
    DATE_FORMAT(order_date, '%Y-%m')    AS month,
    COUNT(*)                            AS total_orders,
    SUM(total_amount)                   AS monthly_revenue
FROM orders
WHERE status NOT IN ('Cancelled', 'Returned')
GROUP BY month
ORDER BY month;

-- 4.3 Payment method preference
SELECT
    payment_method,
    COUNT(*)                                                AS order_count,
    ROUND(SUM(total_amount), 0)                             AS total_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)      AS pct_of_orders
FROM orders
GROUP BY payment_method
ORDER BY order_count DESC;

-- ============================================================
-- SECTION 5: QUICK SANITY CHECK QUERIES
-- ============================================================

-- 5.1 Top 5 customers by number of orders
SELECT
    c.customer_name,
    c.city,
    COUNT(o.order_id) AS num_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY num_orders DESC
LIMIT 5;

-- 5.2 Top 5 best-selling products by quantity
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.product_id, p.product_name, p.category
ORDER BY units_sold DESC
LIMIT 5;
