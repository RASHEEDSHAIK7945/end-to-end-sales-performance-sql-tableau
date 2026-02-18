/* ============================================================
   File: 01_staging_quality_checks.sql
   Purpose: Data quality validation on staging layer
   Scope: Orders, Customers, Products, Location
   Layer: Staging
   ============================================================ */

USE SalesDB;
GO
---------------------------------------------------------------
-- 1. NULL & BLANK CHECKS (Critical Columns)
---------------------------------------------------------------

-- Orders: Critical fields
SELECT *
FROM staging.Orders
WHERE Order_Date IS NULL
   OR Ship_Date IS NULL
   OR Customer_ID IS NULL
   OR Product_ID IS NULL
   OR Sales IS NULL
   OR Quantity IS NULL
   OR Profit IS NULL
   OR Discount IS NULL
   OR LTRIM(RTRIM(Order_ID)) = ''
   OR LTRIM(RTRIM(Customer_ID)) = ''
   OR LTRIM(RTRIM(Product_ID)) = '';

-- Customers
SELECT *
FROM staging.Customers
WHERE Customer_ID IS NULL OR LTRIM(RTRIM(Customer_ID)) = ''
   OR Customer_Name IS NULL OR LTRIM(RTRIM(Customer_Name)) = '';

-- Products
SELECT *
FROM staging.Products
WHERE Product_ID IS NULL OR LTRIM(RTRIM(Product_ID)) = ''
   OR Product_Name IS NULL OR LTRIM(RTRIM(Product_Name)) = '';

-- Location
SELECT *
FROM staging.Location
WHERE Postal_Code IS NULL OR LTRIM(RTRIM(Postal_Code)) = ''
   OR Region IS NULL OR LTRIM(RTRIM(Region)) = '';

---------------------------------------------------------------
-- 2. DUPLICATE CHECKS (Primary & Business Keys)
---------------------------------------------------------------

-- Duplicate order lines (Order_ID + Product_ID)
SELECT Order_ID, Product_ID, COUNT(*) AS duplicate_count
FROM staging.Orders
GROUP BY Order_ID, Product_ID
HAVING COUNT(*) > 1;

-- Duplicate dimension keys
SELECT Customer_ID, COUNT(*) AS cnt
FROM staging.Customers
GROUP BY Customer_ID
HAVING COUNT(*) > 1;

SELECT Product_ID, COUNT(*) AS cnt
FROM staging.Products
GROUP BY Product_ID
HAVING COUNT(*) > 1;

SELECT Postal_Code, COUNT(*) AS cnt
FROM staging.Location
GROUP BY Postal_Code
HAVING COUNT(*) > 1;

---------------------------------------------------------------
-- 3. BUSINESS RULE VALIDATIONS (Invalid / Zero / Negative)
---------------------------------------------------------------

-- Sales & Quantity should be positive
SELECT *
FROM staging.Orders
WHERE Sales <= 0 OR Quantity <= 0;

-- Extreme negative profit (sanity threshold)
SELECT *
FROM staging.Orders
WHERE Profit IS NOT NULL AND Profit < -100000;

---------------------------------------------------------------
-- 4. REFERENTIAL INTEGRITY (Orphan Records)
---------------------------------------------------------------

-- Orders without matching customer
SELECT o.*
FROM staging.Orders o
LEFT JOIN staging.Customers c 
  ON o.Customer_ID = c.Customer_ID
WHERE c.Customer_ID IS NULL;

-- Orders without matching product
SELECT o.*
FROM staging.Orders o
LEFT JOIN staging.Products p 
  ON o.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

-- Orders without matching location
SELECT o.*
FROM staging.Orders o
LEFT JOIN staging.Location l 
  ON o.Postal_Code = l.Postal_Code
WHERE l.Postal_Code IS NULL;

---------------------------------------------------------------
-- 5. DATE VALIDATIONS
---------------------------------------------------------------

-- Future-dated orders
SELECT *
FROM staging.Orders
WHERE Order_Date > GETDATE();

-- Unreasonably old dates
SELECT *
FROM staging.Orders
WHERE Order_Date < '2000-01-01';

---------------------------------------------------------------
-- 6. TEXT STANDARDIZATION CHECKS (Case Consistency)
---------------------------------------------------------------

-- Mixed-case region values
SELECT DISTINCT Region
FROM staging.Location
WHERE Region COLLATE Latin1_General_CS_AS != UPPER(Region);

---------------------------------------------------------------
-- 7. BASIC VOLUME & DISTRIBUTION SANITY CHECKS
---------------------------------------------------------------

-- Row counts
SELECT 'Orders' AS table_name, COUNT(*) AS row_count FROM staging.Orders
UNION ALL
SELECT 'Customers', COUNT(*) FROM staging.Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM staging.Products
UNION ALL
SELECT 'Location', COUNT(*) FROM staging.Location;

-- Sales distribution (outlier detection)
SELECT
    MIN(Sales) AS min_sales,
    MAX(Sales) AS max_sales,
    AVG(Sales) AS avg_sales
FROM staging.Orders;
