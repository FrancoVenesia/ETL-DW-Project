USE STAGING_TDC;
GO

CREATE OR ALTER VIEW dbo.VW_PRD_Stock AS


WITH cleaned AS (
    SELECT 
        REPLACE(STOCK_DATE, ':60', ':59') AS stock_date_cleaned,
        PRODUCT_ID,
        VARIATION
    FROM dbo.STG_PRD_Stock
),
parsed AS (
    SELECT 
        PRODUCT_ID,
        VARIATION,
        -- Estilo 101 (MM/DD/YYYY) explicito: no depende del idioma del login
        CONVERT(DATE, LEFT(stock_date_cleaned, 10), 101) AS fecha_date,
        DATETIMEFROMPARTS(
            YEAR(CONVERT(DATE, LEFT(stock_date_cleaned, 10), 101)),
            MONTH(CONVERT(DATE, LEFT(stock_date_cleaned, 10), 101)),
            DAY(CONVERT(DATE, LEFT(stock_date_cleaned, 10), 101)),
            CASE 
                WHEN RIGHT(stock_date_cleaned, 4) = 'p.m.' AND CAST(SUBSTRING(stock_date_cleaned, 12, 2) AS INT) < 12 
                    THEN CAST(SUBSTRING(stock_date_cleaned, 12, 2) AS INT) + 12
                WHEN RIGHT(stock_date_cleaned, 4) = 'a.m.' AND CAST(SUBSTRING(stock_date_cleaned, 12, 2) AS INT) = 12
                    THEN 0
                ELSE CAST(SUBSTRING(stock_date_cleaned, 12, 2) AS INT)
            END,
            CAST(SUBSTRING(stock_date_cleaned, 15, 2) AS INT), 
            CAST(SUBSTRING(stock_date_cleaned, 18, 2) AS INT), 
            0
        ) AS datetime_24h
    FROM cleaned
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY datetime_24h) AS id_stock,
    fecha_date AS fecha,
    CAST(datetime_24h AS TIME(0)) AS hora,
    PRODUCT_ID AS id_producto,
    VARIATION AS variacion
FROM parsed