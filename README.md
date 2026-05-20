# 🛒 E-Commerce Sales & Customer Analytics — SQL Project

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql) ![GitHub](https://img.shields.io/badge/GitHub-Portfolio-black?logo=github) ![Status](https://img.shields.io/badge/Status-Complete-green)

## 📌 Project Overview

A complete, production-quality SQL data analytics project built on a realistic Indian e-commerce dataset covering **2 years of transactions** (2022–2023). This project demonstrates end-to-end data analyst skills: schema design, data cleaning, exploratory analysis, advanced SQL, business insights, and actionable recommendations.

> **Built for:** Data Analyst / Business Analyst portfolio | Resume | GitHub | Interview preparation

---

## 🎯 Business Problem

An e-commerce company has raw sales data but no structured analytics layer. Business leaders cannot answer basic questions:
- Which customers are about to stop buying?
- Which products are losing money despite high sales?
- Why does revenue dip in Q1 every year?
- Which regions have logistics problems?

**This project solves all of these using SQL.**

---

## 🗃️ Dataset Information

| Table | Rows | Description |
|---|---|---|
| `customers` | 200 | Customer demographics, location, registration date |
| `products` | 40 | Product catalogue with cost and selling price |
| `orders` | 2,000 | Orders with status, payment method, shipping location |
| `order_items` | ~5,000 | Line items — one row per product per order |

**Data Period:** January 2022 – December 2023
**Cities Covered:** Mumbai, Delhi, Bengaluru, Hyderabad, Chennai, Kolkata, Pune, Ahmedabad, Jaipur, Lucknow, Surat, Chandigarh

---

## 🗺️ Database Schema (ERD)

```
customers (PK: customer_id)
    │
    └──< orders (PK: order_id, FK: customer_id)
              │
              └──< order_items (PK: order_item_id, FK: order_id, FK: product_id)
                        │
              products >──┘ (PK: product_id)
```

---

## 🛠️ Tech Stack

| Tool | Version | Purpose |
|---|---|---|
| MySQL | 8.0+ | Database engine |
| MySQL Workbench | 8.0 | SQL IDE and schema visualisation |
| Python | 3.x | Dataset generation |
| Git | Latest | Version control |
| GitHub | — | Portfolio hosting |

---

## 📂 Folder Structure

```
SQL_Ecommerce_Analytics_Project/
│
├── datasets/
│   ├── customers.csv          # 200 customers
│   ├── products.csv           # 40 products
│   ├── orders.csv             # 2,000 orders
│   └── order_items.csv        # ~5,000 line items
│
├── sql_scripts/
│   ├── 01_database_creation.sql   # DB setup
│   ├── 02_table_creation.sql      # Schema + indexes + FK constraints
│   ├── 03_data_cleaning.sql       # Full data quality checks
│   ├── 04_exploratory_analysis.sql # EDA queries
│   ├── 05_business_analysis.sql   # Revenue, RFM, regional analysis
│   └── 06_advanced_queries.sql    # Window functions, views, procedures
│
├── outputs/
│   ├── screenshots/           # Query result screenshots
│   └── query_results/         # Exported result CSVs
│
├── presentation/
│   └── project_summary.md     # One-page executive brief
│
├── README.md                  # This file
├── insights.md                # Full business insights + recommendations
└── interview_prep.md          # 17 Q&A pairs for interview preparation
```

---

## 🚀 How to Run This Project

### Prerequisites
- MySQL 8.0+ installed
- MySQL Workbench installed
- Git installed

### Step 1: Clone the Repository
```bash
git clone https://github.com/ritish-reddy/SQL_Ecommerce_Analytics_Project.git
cd SQL_Ecommerce_Analytics_Project
```

### Step 2: Open MySQL Workbench
- Launch MySQL Workbench
- Connect to your local MySQL server (localhost:3306)
- Open a new Query tab

### Step 3: Run Scripts in Order
```sql
-- Run these one at a time, in this exact order:
SOURCE sql_scripts/01_database_creation.sql;
SOURCE sql_scripts/02_table_creation.sql;
```

### Step 4: Import CSV Data
In MySQL Workbench:
1. Right-click the `customers` table → Table Data Import Wizard
2. Select `datasets/customers.csv`
3. Map columns → Finish
4. Repeat for `products.csv`, `orders.csv`, `order_items.csv`
   *(Import in this order to respect foreign keys)*

### Step 5: Run Analysis Scripts
```sql
SOURCE sql_scripts/03_data_cleaning.sql;
SOURCE sql_scripts/04_exploratory_analysis.sql;
SOURCE sql_scripts/05_business_analysis.sql;
SOURCE sql_scripts/06_advanced_queries.sql;
```

---

## 📊 SQL Concepts Used

| Concept | File | Purpose |
|---|---|---|
| DDL (CREATE, DROP) | 01, 02 | Schema design |
| Constraints (PK, FK, UNIQUE) | 02 | Data integrity |
| Indexes | 02 | Query performance |
| NULL checks, CASE WHEN | 03, 04 | Data cleaning & bucketing |
| Aggregate Functions | 04, 05 | COUNT, SUM, AVG, MIN, MAX |
| GROUP BY + HAVING | 04, 05 | Grouped filtering |
| JOINs (INNER, LEFT, SELF) | 05, 06 | Multi-table queries |
| Subqueries | 05, 06 | Nested logic |
| CTEs (WITH clause) | 05, 06 | Readable multi-step logic |
| Window Functions | 05, 06 | LAG, RANK, NTILE, SUM OVER |
| Date Functions | 04, 05 | DATE_FORMAT, DATEDIFF |
| Views | 06 | Reusable query layer |
| Stored Procedures | 06 | Parameterised reporting |
| EXPLAIN | 06 | Query optimisation |

---

## 🔑 Key Business Insights

1. **Top 15% of customers generate ~45% of revenue** → Launch VIP loyalty programme
2. **COD has 2× higher cancellation rate** than prepaid → Restrict COD above ₹15,000
3. **20% of customers are at churn risk** → Send win-back discount emails
4. **Electronics = 55% of revenue** but highest return exposure → Bundle strategy needed
5. **Books have highest profit margin (45%)** despite low volume → Cross-sell at checkout
6. **Revenue peaks in October–December** (festive season) → Plan inventory in August

---

## 📈 Future Improvements

- [ ] Connect to Power BI / Tableau for visual dashboards
- [ ] Add customer review sentiment data
- [ ] Build demand forecasting model using Python + SQL
- [ ] Implement table partitioning for scalability to 100M+ rows
- [ ] Add automated daily reporting via Stored Procedures + Events

---

## 👤 Author

**Ritish**
📍 Hyderabad, Telangana
🎓 B.Tech CSE — JNTU Hyderabad (2026)
🔗 [LinkedIn](https://linkedin.com/in/ritishreddy04) | [GitHub](https://github.com/ritish-reddy)

*Open to Data Analyst and Business Analyst opportunities.*

