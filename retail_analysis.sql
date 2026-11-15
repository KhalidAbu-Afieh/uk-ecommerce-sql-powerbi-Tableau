CREATE DATABASE retail_project;
USE retail_project;

CREATE TABLE raw_retail (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate VARCHAR(50),
    UnitPrice DECIMAL(10, 2),
    CustomerID VARCHAR(20),
    Country VARCHAR(100)
);

USE retail_project;
SELECT InvoiceDate FROM raw_retail LIMIT 5;

USE retail_project;

CREATE OR REPLACE VIEW clean_sales AS
SELECT 
    InvoiceNo,
    StockCode,
    TRIM(Description) AS ProductDescription,
    Quantity,
    CASE 
        WHEN InvoiceDate LIKE '%/%' THEN STR_TO_DATE(InvoiceDate, '%d/%m/%Y %H:%i')
        ELSE STR_TO_DATE(InvoiceDate, '%Y-%m-%d %H:%i:%s')
    END AS OrderDate,
    UnitPrice,
    ROUND(Quantity * UnitPrice, 2) AS TotalRevenue,
    CustomerID,
    Country
FROM raw_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL 
  AND CustomerID != ''
  AND Quantity > 0
  AND UnitPrice > 0;

CREATE OR REPLACE VIEW customer_rfm AS
WITH rfm_base AS (
    SELECT 
        CustomerID,
        Country,
        DATEDIFF((SELECT MAX(OrderDate) FROM clean_sales), MAX(OrderDate)) AS RecencyDays,
        COUNT(DISTINCT InvoiceNo) AS Frequency,
        ROUND(SUM(TotalRevenue), 2) AS Monetary
    FROM clean_sales
    GROUP BY CustomerID, Country
),
rfm_scores AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY RecencyDays DESC) AS R_Score,
        NTILE(4) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(4) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM rfm_base
)
SELECT *,
    CASE 
        WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Champions'
        WHEN R_Score >= 3 AND F_Score >= 2 THEN 'Loyal Customers'
        WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At-Risk High Value'
        ELSE 'Needs Attention / Hibernating'
    END AS CustomerSegment
FROM rfm_scores;
SELECT * FROM customer_rfm LIMIT 10;

USE retail_project;

CREATE OR REPLACE VIEW clean_sales AS
SELECT 
    InvoiceNo,
    StockCode,
    TRIM(Description) AS ProductDescription,
    Quantity,
    COALESCE(
        STR_TO_DATE(InvoiceDate, '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(InvoiceDate, '%d/%m/%Y %H:%i'),
        STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
    ) AS OrderDate,
    UnitPrice,
    ROUND(Quantity * UnitPrice, 2) AS TotalRevenue,
    CustomerID,
    Country
FROM raw_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND CustomerID IS NOT NULL 
  AND CustomerID != ''
  AND Quantity > 0
  AND UnitPrice > 0
  AND COALESCE(
        STR_TO_DATE(InvoiceDate, '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(InvoiceDate, '%d/%m/%Y %H:%i'),
        STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
      ) IS NOT NULL;

SELECT * FROM customer_rfm LIMIT 10;
