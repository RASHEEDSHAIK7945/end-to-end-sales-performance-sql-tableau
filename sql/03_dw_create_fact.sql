/* ============================================================
   File: 03_dw_create_fact.sql
   Purpose: Create fact table for Sales transactions
   Database: SalesDB
   Schema: dw
   ============================================================ */

USE SalesDB;
GO

-------------------------------------------------
-- Fact: Orders (Order Line Grain)
-------------------------------------------------
CREATE TABLE dw.Fact_Orders (
    Fact_Key BIGINT IDENTITY(1,1) PRIMARY KEY,   -- Surrogate key for fact table

    Order_ID VARCHAR(50) NOT NULL,               -- Degenerate dimension (business identifier)
    Date_Key INT NOT NULL,
    Customer_Key INT NOT NULL,
    Product_Key INT NOT NULL,
    Location_Key INT NOT NULL,

    Sales DECIMAL(12,2) NOT NULL,
    Profit DECIMAL(12,2),
    Quantity INT NOT NULL,

    -------------------------------------------------
    -- Foreign Keys
    -------------------------------------------------
    CONSTRAINT Fk_Fact_Date 
        FOREIGN KEY (Date_Key) 
        REFERENCES dw.dim_Date(Date_Key),

    CONSTRAINT Fk_Fact_Customer 
        FOREIGN KEY (Customer_Key) 
        REFERENCES dw.dim_Customers(Customer_Key),

    CONSTRAINT Fk_Fact_Product 
        FOREIGN KEY (Product_Key) 
        REFERENCES dw.dim_Products(Product_Key),

    CONSTRAINT Fk_Fact_Location 
        FOREIGN KEY (Location_Key) 
        REFERENCES dw.dim_Location(Location_Key),

    -------------------------------------------------
    -- Data Quality Constraints
    -------------------------------------------------
    CONSTRAINT chk_sales_non_negative CHECK (Sales >= 0),
    CONSTRAINT chk_quantity_positive CHECK (Quantity > 0)
);
