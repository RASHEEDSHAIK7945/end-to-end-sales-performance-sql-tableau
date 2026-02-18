/* ============================================================
   File: 06_dw_create_analytics_views.sql
   Purpose: BI-ready analytical views for Tableau consumption
   Database: SalesDB
   Schema: analytics
   Notes:
     - Centralizes KPI logic in SQL
     - Simplifies Tableau models
     - Supports YoY, monthly, weekly, product & customer analysis
   ============================================================ */

USE SalesDB;
GO

-------------------------------------------------
-- 1) KPI OVERVIEW (Yearly KPIs)
-------------------------------------------------
CREATE OR ALTER VIEW analytics.vw_kpi_yearly AS
SELECT
    d.Year,
    SUM(f.Sales)    AS Total_Sales,
    SUM(f.Profit)   AS Total_Profit,
    SUM(f.Quantity) AS Total_Quantity,
    COUNT(DISTINCT f.Order_ID) AS Total_Orders,
    COUNT(DISTINCT f.Customer_Key) AS Total_Customers
FROM dw.Fact_Orders f
JOIN dw.dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Year;
GO

-------------------------------------------------
-- 2) MONTHLY TRENDS (for YoY comparisons)
-------------------------------------------------
CREATE OR ALTER VIEW analytics.vw_monthly_trends AS
SELECT
    d.Year,
    d.Month,
    d.Month_name,
    SUM(f.Sales)    AS Sales,
    SUM(f.Profit)   AS Profit,
    SUM(f.Quantity) AS Quantity
FROM dw.Fact_Orders f
JOIN dw.dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Year, d.Month, d.Month_name;
GO

-------------------------------------------------
-- 3) WEEKLY SALES & PROFIT vs AVERAGE (CY focus in Tableau)
-------------------------------------------------
CREATE OR ALTER VIEW analytics.vw_weekly_sales_profit_vs_avg AS
WITH weekly AS (
    SELECT
        d.Year,
        d.Week,
        SUM(f.Sales)  AS Weekly_Sales,
        SUM(f.Profit) AS Weekly_Profit
    FROM dw.Fact_Orders f
    JOIN dw.dim_Date d ON f.Date_Key = d.Date_Key
    GROUP BY d.Year, d.Week
),
avg_weekly AS (
    SELECT
        Year,
        AVG(Weekly_Sales)  AS Avg_Weekly_Sales,
        AVG(Weekly_Profit) AS Avg_Weekly_Profit
    FROM weekly
    GROUP BY Year
)
SELECT
    w.Year,
    w.Week,
    w.Weekly_Sales,
    a.Avg_Weekly_Sales,
    CASE WHEN w.Weekly_Sales >= a.Avg_Weekly_Sales THEN 1 ELSE 0 END AS Is_Above_Avg_Sales,
    w.Weekly_Profit,
    a.Avg_Weekly_Profit,
    CASE WHEN w.Weekly_Profit >= a.Avg_Weekly_Profit THEN 1 ELSE 0 END AS Is_Above_Avg_Profit
FROM weekly w
JOIN avg_weekly a ON w.Year = a.Year;
GO

-------------------------------------------------
-- 4) PRODUCT SUB-CATEGORY PERFORMANCE (Sales vs Profit)
-------------------------------------------------
CREATE OR ALTER VIEW analytics.vw_subcategory_sales_profit AS
SELECT
    p.Category,
    p.Sub_Category,
    d.Year,
    SUM(f.Sales)  AS Sales,
    SUM(f.Profit) AS Profit
FROM dw.Fact_Orders f
JOIN dw.dim_Products p ON f.Product_Key = p.Product_Key
JOIN dw.dim_Date d     ON f.Date_Key    = d.Date_Key
GROUP BY p.Category, p.Sub_Category, d.Year;
GO

-------------------------------------------------
-- 5) CUSTOMER KPIs (Yearly)
-------------------------------------------------
CREATE OR ALTER VIEW analytics.vw_customer_kpis_yearly AS
SELECT
    d.Year,
    COUNT(DISTINCT f.Customer_Key) AS Total_Customers,
    COUNT(DISTINCT f.Order_ID)     AS Total_Orders,
    SUM(f.Sales) / NULLIF(COUNT(DISTINCT f.Customer_Key), 0) AS Sales_Per_Customer
FROM dw.Fact_Orders f
JOIN dw.dim_Date d ON f.Date_Key = d.Date_Key
GROUP BY d.Year;
GO

-------------------------------------------------
-- 6) CUSTOMER DISTRIBUTION BY NUMBER OF ORDERS
-------------------------------------------------
CREATE OR ALTER VIEW analytics.vw_customer_order_distribution AS
WITH customer_orders AS (
    SELECT
        f.Customer_Key,
        COUNT(DISTINCT f.Order_ID) AS Orders_Count
    FROM dw.Fact_Orders f
    GROUP BY f.Customer_Key
)
SELECT
    Orders_Count,
    COUNT(*) AS Customers_Count
FROM customer_orders
GROUP BY Orders_Count;
GO

-------------------------------------------------
-- 7) TOP 10 CUSTOMERS BY PROFIT (Yearly)
-------------------------------------------------
CREATE OR ALTER VIEW analytics.vw_top_customers_by_profit AS
WITH customer_profit AS (
    SELECT
        c.Customer_Key,
        c.Customer_ID,
        c.Customer_Name,
        d.Year,
        COUNT(DISTINCT f.Order_ID) AS Orders_Count,
        SUM(f.Sales)  AS Sales,
        SUM(f.Profit) AS Profit,
        MAX(d.Full_Date) AS Last_Order_Date
    FROM dw.Fact_Orders f
    JOIN dw.dim_Customers c ON f.Customer_Key = c.Customer_Key
    JOIN dw.dim_Date d      ON f.Date_Key     = d.Date_Key
    GROUP BY c.Customer_Key, c.Customer_ID, c.Customer_Name, d.Year
)
SELECT
    Year,
    Customer_ID,
    Customer_Name,
    Orders_Count,
    Sales,
    Profit,
    Last_Order_Date,
    RANK() OVER (PARTITION BY Year ORDER BY Profit DESC) AS Profit_Rank
FROM customer_profit;
GO
