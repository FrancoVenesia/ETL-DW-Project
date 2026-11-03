USE STAGING_TDC;
GO

CREATE OR ALTER VIEW dbo.VW_VTA_Precios AS

-- Cada precio rige desde PRICE_DATE (fecha y hora) hasta el siguiente precio del mismo producto.
-- Con el rango armado, las ventas buscan su precio con un join en vez de un TOP 1 por linea.
SELECT
    p.id_producto,
    p.vigente_desde,
    LEAD(p.vigente_desde) OVER (PARTITION BY p.id_producto ORDER BY p.vigente_desde) AS vigente_hasta,
    p.precio
FROM (
    SELECT
        TRY_CONVERT(INT, PRODUCT_ID) AS id_producto,
        TRY_CONVERT(DATETIME2(0), PRICE_DATE) AS vigente_desde,
        TRY_CONVERT(DECIMAL(12,2), PRICE) AS precio
    FROM STAGING_TDC.dbo.STG_VTA_MySQL_Prices
) p;
