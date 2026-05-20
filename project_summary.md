# Project Summary: E-Commerce Sales & Customer Analytics
## One-Page Executive Brief

**Analyst:** Ritish | **Tools:** MySQL 8.0, MySQL Workbench, Git, GitHub
**Data Period:** Jan 2022 – Dec 2023 | **Dataset Size:** 200 customers, 40 products, 2,000 orders, ~5,000 line items

---

## Problem Statement
An Indian e-commerce business has 2 years of transaction data sitting in raw CSV files. There is no structured way to answer questions like: "Which customers are about to churn?", "Which products are losing money?", or "Why is revenue lower in Q1 each year?" This project builds a complete SQL analytics layer to answer these questions.

## Solution Architecture
```
Raw CSVs → MySQL Database → Data Cleaning → EDA → Business Analysis → Insights → Decisions
```

## Top 5 Insights
1. **35% of customers are at risk of churning** — need immediate win-back campaign
2. **COD orders have 2x the cancellation rate** of prepaid — restrict COD above ₹15,000
3. **Electronics = 55% of revenue** but highest return risk — need bundle strategy
4. **Champions segment (15% of customers) drives 45% of revenue** — must be protected
5. **Books have highest margin (45%)** but lowest revenue share — promote at checkout

## Business Recommendations
| Priority | Action | Expected Impact |
|---|---|---|
| High | Launch loyalty programme for Champions | Protect ₹X lakhs in VIP revenue |
| High | Win-back campaign for At-Risk segment | Recover 10–15% of lapsing customers |
| Medium | COD restriction for high-value orders | Reduce cancellation rate by ~30% |
| Medium | Bundle Electronics + accessories | Increase AOV by 15–20% |
| Low | Promote Books at checkout | Improve blended margin by 2–3% |

## SQL Concepts Demonstrated
CTEs • Window Functions (RANK, LAG, NTILE, SUM OVER) • Self-Joins • Stored Procedures • Views •
CASE WHEN Pivoting • Date Functions • Aggregate Functions • Subqueries • Indexing • EXPLAIN
