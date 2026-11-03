CREATE OR ALTER VIEW dbo.VW_VTA_MySQL_Lineas AS

WITH LineasVenta AS (
    SELECT
        TRY_CONVERT(INT, bd.BILLING_ID) AS id_venta_sistema,
        TRY_CONVERT(VARCHAR(255), bd.BILLING_ID) AS nro_factura,
        TRY_CONVERT(DATE, b.BILLING_DATE) AS fecha,
        TRY_CONVERT(INT, b.CUSTOMER_ID) AS id_cliente,
        TRY_CONVERT(INT, b.EMPLOYEE_ID) AS id_empleado,
        TRY_CONVERT(INT, bd.PRODUCT_ID) AS id_producto,
        TRY_CONVERT(INT, bd.QUANTITY) AS cantidad,
        CASE WHEN b.BILLING_ID IS NULL THEN 0 ELSE 1 END AS tiene_cabecera
    FROM STAGING_TDC.dbo.STG_VTA_MySQL_BillingDetail bd
    -- LEFT JOIN: el origen trae detalles cuya factura no existe en billing
    LEFT JOIN STAGING_TDC.dbo.STG_VTA_MySQL_Billing b
        ON b.BILLING_ID = bd.BILLING_ID
),

LineasConPrecio AS (
    SELECT
        lv.*,
        TRY_CONVERT(DECIMAL(12,2), pr.PRICE) AS precio_unitario
    FROM LineasVenta lv
    OUTER APPLY (
        SELECT TOP 1
            p.PRICE
        FROM STAGING_TDC.dbo.STG_VTA_MySQL_Prices p
        WHERE TRY_CONVERT(INT, p.PRODUCT_ID) = lv.id_producto
          AND TRY_CONVERT(DATE, p.PRICE_DATE) <= lv.fecha
        ORDER BY TRY_CONVERT(DATE, p.PRICE_DATE) DESC
    ) pr
),

LineasConMotivo AS (
    SELECT
        lp.*,
        CASE
            WHEN lp.tiene_cabecera = 0
                THEN 'FACTURA_SIN_CABECERA'
            WHEN NOT EXISTS (SELECT 1 FROM dbo.VW_PRD_Products prod WHERE prod.PRODUCT_ID = lp.id_producto)
                THEN 'PRODUCTO_INEXISTENTE'
            WHEN lp.precio_unitario IS NULL
                THEN 'SIN_PRECIO_VIGENTE'
        END AS motivo_rechazo
    FROM LineasConPrecio lp
)

-- Una linea rechazada invalida toda su factura: sin ella no se puede calcular el total ni el descuento
SELECT
    lm.*,
    COUNT(lm.motivo_rechazo) OVER (PARTITION BY lm.nro_factura) AS lineas_rechazadas_factura
FROM LineasConMotivo lm;
