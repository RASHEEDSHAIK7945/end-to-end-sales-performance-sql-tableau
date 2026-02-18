/* ============================================================
   File: 02_dw_create_dimensions.sql
   Purpose: Create dimension tables for the Sales Data Warehouse
   Database: SalesDB
   Schema: dw
   ============================================================ */

USE SalesDB;
GO

-------------------------------------------------
-- Dimension: Customers
-------------------------------------------------
CREATE TABLE dw.dim_Customers (
    Customer_Key INT IDENTITY(1,1) PRIMARY KEY,
    Customer_ID VARCHAR(50) NOT NULL UNIQUE,
    Customer_Name NVARCHAR(150),
    Segment NVARCHAR(50)
);

-------------------------------------------------
-- Dimension: Products
-------------------------------------------------
CREATE TABLE dw.dim_Products (
    Product_Key INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID VARCHAR(50) NOT NULL UNIQUE,
    Product_Name NVARCHAR(200),
    Category NVARCHAR(100),
    Sub_Category NVARCHAR(100)
);

-------------------------------------------------
-- Dimension: Location
-------------------------------------------------
CREATE TABLE dw.dim_Location (
    Location_Key INT IDENTITY(1,1) PRIMARY KEY,
    Postal_Code VARCHAR(20) NOT NULL UNIQUE,
    Region NVARCHAR(50),
    State NVARCHAR(100),
    City NVARCHAR(100)
);

-------------------------------------------------
-- Dimension: Date
-------------------------------------------------
CREATE TABLE dw.dim_Date (
    Date_Key INT PRIMARY KEY,         -- Format: YYYYMMDD
    Full_Date DATE NOT NULL,
    Year INT,
    Month INT,
    Month_name VARCHAR(20),
    Week INT,
    Quarter INT
);
