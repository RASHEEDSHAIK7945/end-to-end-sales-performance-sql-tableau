/* ============================================================
   File: 04_dw_load_dimensions.sql
   Purpose: Load and standardize dimension tables from staging
   Database: SalesDB
   Schema: dw
   Notes:
     - Applies trimming and case standardization
     - Deduplicates source records
     - Handles missing postal codes
     - Prevents duplicate inserts (idempotent load)
   ============================================================ */

USE SalesDB;
GO

-------------------------------------------------
-- 1. Load dim_Customers
-------------------------------------------------
INSERT INTO dw.dim_Customers (Customer_ID, Customer_Name, Segment)
SELECT DISTINCT
    LTRIM(RTRIM(s.Customer_ID)) AS Customer_ID,

    -- Standardize customer name (simple title case)
    CONCAT(
        UPPER(LEFT(LTRIM(RTRIM(s.Customer_Name)), 1)),
        LOWER(SUBSTRING(LTRIM(RTRIM(s.Customer_Name)), 2, LEN(LTRIM(RTRIM(s.Customer_Name)))))
    ) AS Customer_Name,

    -- Segment not available in source
    NULL AS Segment
FROM staging.Customers s
WHERE NOT EXISTS (
    SELECT 1
    FROM dw.dim_Customers d
    WHERE d.Customer_ID = LTRIM(RTRIM(s.Customer_ID))
);

-------------------------------------------------
-- 2. Load dim_Products (deduplicated by Product_ID)
-------------------------------------------------
WITH dedup_products AS (
    SELECT
        LTRIM(RTRIM(Product_ID)) AS Product_ID,
        LTRIM(RTRIM(Product_Name)) AS Product_Name,
        UPPER(LTRIM(RTRIM(Category))) AS Category,
        UPPER(LTRIM(RTRIM(Sub_Category))) AS Sub_Category,
        ROW_NUMBER() OVER (
            PARTITION BY LTRIM(RTRIM(Product_ID))
            ORDER BY Product_Name  -- deterministic tie-breaker
        ) AS rn
    FROM staging.Products
)
INSERT INTO dw.dim_Products (Product_ID, Product_Name, Category, Sub_Category)
SELECT
    Product_ID,
    Product_Name,
    Category,
    Sub_Category
FROM dedup_products dp
WHERE dp.rn = 1
  AND NOT EXISTS (
      SELECT 1
      FROM dw.dim_Products d
      WHERE d.Product_ID = dp.Product_ID
  );

-------------------------------------------------
-- 3. Load dim_Location (handle missing Postal_Code)
-------------------------------------------------
WITH dedup_location AS (
    SELECT
        COALESCE(NULLIF(LTRIM(RTRIM(Postal_Code)), ''), 'UNKNOWN') AS Postal_Code,
        UPPER(LTRIM(RTRIM(Region))) AS Region,
        UPPER(LTRIM(RTRIM(State))) AS State,

        -- Standardize city name (simple title case)
        CONCAT(
            UPPER(LEFT(LTRIM(RTRIM(City)), 1)),
            LOWER(SUBSTRING(LTRIM(RTRIM(City)), 2, LEN(LTRIM(RTRIM(City)))))
        ) AS City,

        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(NULLIF(LTRIM(RTRIM(Postal_Code)), ''), 'UNKNOWN')
            ORDER BY Postal_Code
        ) AS rn
    FROM staging.Location
)
INSERT INTO dw.dim_Location (Postal_Code, Region, State, City)
SELECT
    Postal_Code,
    Region,
    State,
    City
FROM dedup_location dl
WHERE dl.rn = 1
  AND NOT EXISTS (
      SELECT 1
      FROM dw.dim_Location d
      WHERE d.Postal_Code = dl.Postal_Code
  );

-------------------------------------------------
-- 4. Load dim_Date (derived from Orders)
-------------------------------------------------
INSERT INTO dw.dim_Date (Date_Key, Full_Date, Year, Month, Month_name, Week, Quarter)
SELECT DISTINCT
    CONVERT(INT, FORMAT(o.Order_Date, 'yyyyMMdd')) AS Date_Key,
    o.Order_Date AS Full_Date,
    YEAR(o.Order_Date) AS Year,
    MONTH(o.Order_Date) AS Month,
    DATENAME(MONTH, o.Order_Date) AS Month_name,
    DATEPART(WEEK, o.Order_Date) AS Week,
    DATEPART(QUARTER, o.Order_Date) AS Quarter
FROM staging.Orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM dw.dim_Date d
    WHERE d.Date_Key = CONVERT(INT, FORMAT(o.Order_Date, 'yyyyMMdd'))
);
