/* ============================================================
   File: 05_dw_load_fact.sql
   Purpose: Load fact table (Fact_Orders) from staging data
   Database: SalesDB
   Schema: dw
   Notes:
     - Maps business keys to surrogate keys in dimensions
     - Enforces referential integrity
     - Idempotent load (prevents duplicate inserts)
   ============================================================ */

USE SalesDB;
GO

-------------------------------------------------
-- Load Fact_Orders
-- Grain: Order line (Order_ID + Product_ID)
-------------------------------------------------
INSERT INTO dw.Fact_Orders (
    Order_ID,
    Date_Key,
    Customer_Key,
    Product_Key,
    Location_Key,
    Sales,
    Profit,
    Quantity
)
SELECT
    o.Order_ID,
    CONVERT(INT, FORMAT(o.Order_Date, 'yyyyMMdd')) AS Date_Key,
    c.Customer_Key,
    p.Product_Key,
    l.Location_Key,
    o.Sales,
    o.Profit,
    o.Quantity
FROM staging.Orders o
JOIN dw.dim_Customers c
  ON c.Customer_ID = LTRIM(RTRIM(o.Customer_ID))
JOIN dw.dim_Products p
  ON p.Product_ID = LTRIM(RTRIM(o.Product_ID))
JOIN dw.dim_Location l
  ON l.Postal_Code = COALESCE(NULLIF(LTRIM(RTRIM(o.Postal_Code)), ''), 'UNKNOWN')
WHERE NOT EXISTS (
    SELECT 1
    FROM dw.Fact_Orders f
    WHERE f.Order_ID = o.Order_ID
      AND f.Product_Key = p.Product_Key
);
