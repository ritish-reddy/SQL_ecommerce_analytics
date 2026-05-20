-- ============================================================
-- FILE: 02_table_creation.sql
-- PROJECT: E-Commerce Sales & Customer Analytics
-- PURPOSE: Define all 4 tables + relationships (schema design)
-- ============================================================
-- WHY 4 TABLES?
-- Real databases never store everything in one giant table.
-- We separate concerns: Customers, Products, Orders, Order_Items.
-- This is called NORMALIZATION — removing data duplication.
-- ============================================================

USE ecommerce_analytics;

-- ---------------------------------------------------------------
-- DROP TABLES IN REVERSE ORDER (child tables first, then parents)
-- ---------------------------------------------------------------
-- We drop old tables before re-creating them so the script is re-runnable.
-- ORDER MATTERS: order_items references orders and products,
-- so we must drop order_items BEFORE orders/products.

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- ---------------------------------------------------------------
-- TABLE 1: customers
-- ---------------------------------------------------------------
-- Stores one row per unique customer.
-- PRIMARY KEY = customer_id (unique identifier for each customer).
-- ENUM restricts gender to only 'Male' or 'Female' — data quality control.

CREATE TABLE customers (
    customer_id       INT           NOT NULL AUTO_INCREMENT,
    customer_name     VARCHAR(100)  NOT NULL,
    email             VARCHAR(150)  NOT NULL UNIQUE,
    phone             VARCHAR(15),
    city              VARCHAR(60),
    state             VARCHAR(60),
    registration_date DATE,
    age               TINYINT       UNSIGNED,
    gender            ENUM('Male','Female','Other'),
    PRIMARY KEY (customer_id)
);

-- ---------------------------------------------------------------
-- TABLE 2: products
-- ---------------------------------------------------------------
-- Stores one row per unique product.
-- unit_price = what the customer pays.
-- cost_price = what the company paid (used to compute profit).

CREATE TABLE products (
    product_id    INT            NOT NULL AUTO_INCREMENT,
    product_name  VARCHAR(150)   NOT NULL,
    category      VARCHAR(80)    NOT NULL,
    unit_price    DECIMAL(10,2)  NOT NULL,
    cost_price    DECIMAL(10,2)  NOT NULL,
    PRIMARY KEY (product_id)
);

-- ---------------------------------------------------------------
-- TABLE 3: orders
-- ---------------------------------------------------------------
-- One row per order placed by a customer.
-- FOREIGN KEY customer_id references customers(customer_id)
--   → you cannot insert an order for a customer that doesn't exist.
-- status ENUM limits values to prevent junk data entry.
-- total_amount is the final billed amount (includes all items).

CREATE TABLE orders (
    order_id        INT            NOT NULL AUTO_INCREMENT,
    customer_id     INT            NOT NULL,
    order_date      DATE           NOT NULL,
    status          ENUM('Delivered','Shipped','Cancelled','Returned','Processing') NOT NULL,
    payment_method  VARCHAR(50),
    total_amount    DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    shipping_city   VARCHAR(60),
    shipping_state  VARCHAR(60),
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- TABLE 4: order_items
-- ---------------------------------------------------------------
-- One row per product line within an order.
-- An order with 3 products = 3 rows here, 1 row in orders.
-- This is called a "junction table" or "line items table".
-- line_total = (unit_price - discount) × quantity

CREATE TABLE order_items (
    order_item_id    INT            NOT NULL AUTO_INCREMENT,
    order_id         INT            NOT NULL,
    product_id       INT            NOT NULL,
    quantity         TINYINT        NOT NULL DEFAULT 1,
    unit_price       DECIMAL(10,2)  NOT NULL,
    discount_percent TINYINT        DEFAULT 0,
    sale_price       DECIMAL(10,2)  NOT NULL,
    line_total       DECIMAL(12,2)  NOT NULL,
    PRIMARY KEY (order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id)   ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ---------------------------------------------------------------
-- STEP: ADD INDEXES FOR QUERY PERFORMANCE
-- ---------------------------------------------------------------
-- Indexes speed up WHERE and JOIN operations on large tables.
-- Rule of thumb: index columns you frequently filter or join on.

CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_items_product     ON order_items(product_id);
CREATE INDEX idx_items_order       ON order_items(order_id);
CREATE INDEX idx_customers_city    ON customers(city);
CREATE INDEX idx_customers_state   ON customers(state);

-- ---------------------------------------------------------------
-- VERIFY: List all tables to confirm creation was successful
-- ---------------------------------------------------------------

SHOW TABLES;
