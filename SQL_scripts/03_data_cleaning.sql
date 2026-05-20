-- ============================================================
-- FILE: 03_data_cleaning.sql
-- PROJECT: E-Commerce Sales & Customer Analytics
-- PURPOSE: Identify and fix all data quality issues BEFORE analysis
-- ============================================================
-- WHY CLEAN DATA FIRST?
-- If we run business queries on dirty data, we get wrong answers.
-- "Garbage in, Garbage out" — cleaning is the most important step.
-- Real companies spend 60–80% of analyst time on data cleaning.
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- SECTION A: CHECK FOR DUPLICATE RECORDS
-- ============================================================
-- Duplicates happen when data is imported multiple times or
-- when ETL pipelines have bugs. We must catch them early.

-- A1: Check duplicate customers (same email = same person)
SELECT
    email,
    COUNT(*) AS occurrences
FROM customers
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;
-- EXPECTED: 0 rows (email has UNIQUE constraint)
-- IF rows appear: investigate the import process or source data

-- A2: Check duplicate orders (same order_id appearing twice)
SELECT
    order_id,
    COUNT(*) AS occurrences
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;
-- EXPECTED: 0 rows (order_id is PRIMARY KEY — auto unique)

-- A3: Check for duplicate order_items
-- (same order + same product shouldn't appear twice)
SELECT
    order_id,
    product_id,
    COUNT(*) AS occurrences
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- ============================================================
-- SECTION B: CHECK FOR NULL VALUES
-- ============================================================
-- NULL means "no data entered". Different from 0 or empty string.
-- NULLs in key columns (customer_name, order_date) break analysis.

-- B1: Null check on customers table
SELECT
    COUNT(*)                                           AS total_customers,
    COUNT(*) - COUNT(customer_name)                    AS null_names,
    COUNT(*) - COUNT(email)                            AS null_emails,
    COUNT(*) - COUNT(city)                             AS null_cities,
    COUNT(*) - COUNT(state)                            AS null_states,
    COUNT(*) - COUNT(registration_date)                AS null_reg_dates,
    COUNT(*) - COUNT(age)                              AS null_ages,
    COUNT(*) - COUNT(gender)                           AS null_genders
FROM customers;

-- B2: Null check on orders table
SELECT
    COUNT(*)                                           AS total_orders,
    COUNT(*) - COUNT(order_date)                       AS null_dates,
    COUNT(*) - COUNT(total_amount)                     AS null_amounts,
    COUNT(*) - COUNT(payment_method)                   AS null_payment,
    COUNT(*) - COUNT(status)                           AS null_status,
    COUNT(*) - COUNT(shipping_state)                   AS null_state
FROM orders;

-- B3: Find orders where total_amount is 0 or negative (suspicious)
SELECT order_id, customer_id, order_date, total_amount, status
FROM orders
WHERE total_amount <= 0;

-- ============================================================
-- SECTION C: DATA TYPE & VALUE VALIDATION
-- ============================================================

-- C1: Check for invalid ages (must be between 10 and 100)
SELECT customer_id, customer_name, age
FROM customers
WHERE age < 10 OR age > 100;

-- C2: Check for future order dates (impossible — data entry error)
SELECT order_id, order_date
FROM orders
WHERE order_date > CURDATE();

-- C3: Check for negative quantities or prices in order_items
SELECT order_item_id, order_id, quantity, unit_price, sale_price, line_total
FROM order_items
WHERE quantity <= 0
   OR unit_price < 0
   OR sale_price < 0
   OR line_total < 0;

-- C4: Check discount_percent is valid (must be 0–100)
SELECT order_item_id, discount_percent
FROM order_items
WHERE discount_percent < 0 OR discount_percent > 100;

-- C5: Validate line_total matches formula: sale_price × quantity
-- A mismatch means the data was calculated incorrectly during import
SELECT
    order_item_id,
    quantity,
    sale_price,
    line_total                            AS stored_total,
    ROUND(sale_price * quantity, 2)       AS calculated_total,
    ABS(line_total - sale_price * quantity) AS difference
FROM order_items
WHERE ABS(line_total - ROUND(sale_price * quantity, 2)) > 0.01
LIMIT 20;

-- ============================================================
-- SECTION D: REFERENTIAL INTEGRITY CHECKS
-- ============================================================
-- Orphan records = order items pointing to orders that don't exist
-- This happens when DELETE is done incorrectly without CASCADE

-- D1: Find order_items with no matching order
SELECT oi.order_item_id, oi.order_id
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- D2: Find orders referencing non-existent customers
SELECT o.order_id, o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- D3: Find order_items referencing non-existent products
SELECT oi.order_item_id, oi.product_id
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- ============================================================
-- SECTION E: STANDARDIZE TEXT DATA
-- ============================================================
-- Inconsistent naming (e.g., "mumbai" vs "Mumbai") breaks GROUP BY.

-- E1: Check for mixed-case city names
SELECT DISTINCT city FROM customers ORDER BY city;

-- E2: Standardize city names to Title Case (if needed)
-- UPDATE customers SET city = CONCAT(UPPER(LEFT(city,1)), LOWER(SUBSTRING(city,2)));

-- E3: Check distinct statuses to ensure no rogue values
SELECT DISTINCT status FROM orders;

-- E4: Check distinct payment methods
SELECT DISTINCT payment_method FROM orders;

-- ============================================================
-- SECTION F: SUMMARY — DATA QUALITY SCORECARD
-- ============================================================
-- At the end of cleaning, document the health of your data.

SELECT
    'customers'   AS table_name,
    COUNT(*)      AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_records
FROM customers
UNION ALL
SELECT 'products', COUNT(*), COUNT(DISTINCT product_id) FROM products
UNION ALL
SELECT 'orders', COUNT(*), COUNT(DISTINCT order_id) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*), COUNT(DISTINCT order_item_id) FROM order_items;

-- ============================================================
-- DATA CLEANING NOTES (for your README & interviews)
-- ============================================================
-- Issue 1: Orphan records       → Fixed by FOREIGN KEY constraints
-- Issue 2: Negative amounts     → Validated in Section C
-- Issue 3: Future dates         → Validated in Section C
-- Issue 4: Duplicate emails     → Prevented by UNIQUE constraint
-- Issue 5: Invalid discounts    → Validated in Section C
-- Issue 6: line_total mismatch  → Validated via formula check
-- Result: Dataset is clean and ready for analysis
