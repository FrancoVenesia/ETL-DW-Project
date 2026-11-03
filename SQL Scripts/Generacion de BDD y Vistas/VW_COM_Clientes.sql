CREATE OR ALTER VIEW dbo.VW_COM_Clientes AS

-- Los XML traen los zipcodes sin el cero inicial (6550 en vez de 06550)
SELECT
    TRY_CONVERT(INT, CUSTOMER_ID) AS id_cliente,
    CAST(RIGHT('00000' + LTRIM(RTRIM(ZIPCODE)), 5) AS VARCHAR(255)) AS zipcode
FROM STAGING_TDC.dbo.STG_COM_Customer_Retail

UNION ALL

SELECT
    TRY_CONVERT(INT, CUSTOMER_ID) AS id_cliente,
    CAST(RIGHT('00000' + LTRIM(RTRIM(ZIPCODE)), 5) AS VARCHAR(255)) AS zipcode
FROM STAGING_TDC.dbo.STG_COM_Customer_Wholesale;
