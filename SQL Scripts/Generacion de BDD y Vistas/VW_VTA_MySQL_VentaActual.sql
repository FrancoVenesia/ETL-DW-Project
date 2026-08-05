CREATE OR ALTER VIEW dbo.VW_VTA_MySQL_VentaActual AS

WITH Clientes AS (
    SELECT 
        TRY_CONVERT(INT, CUSTOMER_ID) AS id_cliente,
        ZIPCODE AS zipcode
    FROM STAGING_TDC.dbo.STG_COM_Customer_Retail

    UNION ALL

    SELECT 
        TRY_CONVERT(INT, CUSTOMER_ID) AS id_cliente,
        ZIPCODE AS zipcode
    FROM STAGING_TDC.dbo.STG_COM_Customer_Wholesale
),

LineasVenta AS (
    SELECT
        TRY_CONVERT(INT, b.BILLING_ID) AS id_venta_sistema,
        TRY_CONVERT(VARCHAR(255), b.BILLING_ID) AS nro_factura,
        TRY_CONVERT(DATE, b.BILLING_DATE) AS fecha,
        TRY_CONVERT(INT, b.CUSTOMER_ID) AS id_cliente,
        TRY_CONVERT(INT, b.EMPLOYEE_ID) AS id_empleado,
        TRY_CONVERT(INT, bd.PRODUCT_ID) AS id_producto,
        TRY_CONVERT(INT, bd.QUANTITY) AS cantidad
    FROM STAGING_TDC.dbo.STG_VTA_MySQL_Billing b
    INNER JOIN STAGING_TDC.dbo.STG_VTA_MySQL_BillingDetail bd
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

LineasConProductoCliente AS (
    SELECT
        lp.*,
        c.zipcode,
        prod.CM3
    FROM LineasConPrecio lp
    LEFT JOIN Clientes c
        ON lp.id_cliente = c.id_cliente
    INNER JOIN dbo.VW_PRD_Products prod
        ON lp.id_producto = prod.PRODUCT_ID
    WHERE lp.precio_unitario IS NOT NULL
),

LineasConMonto AS (
    SELECT
        *,
        cantidad * (TRY_CONVERT(DECIMAL(12,3), CM3) / 1000.0) AS litros_vendidos,
        cantidad * precio_unitario AS monto_base
    FROM LineasConProductoCliente
),

FacturasConTotal AS (
    SELECT
        *,
        SUM(monto_base) OVER (PARTITION BY nro_factura) AS total_factura
    FROM LineasConMonto
)

SELECT
    2 AS version_sistema,
    id_venta_sistema,

    fecha,
    id_cliente,
    id_empleado,
    id_producto,
    zipcode,
    nro_factura,
    cantidad,
    litros_vendidos,
    precio_unitario,
    monto_base,

    ISNULL(d.PERCENTAGE, 0) AS porcentaje_descuento,

    monto_base * (ISNULL(d.PERCENTAGE, 0) / 100.0) AS monto_descuento,

    monto_base - (
        monto_base * (ISNULL(d.PERCENTAGE, 0) / 100.0)
    ) AS monto_final

FROM FacturasConTotal ft

OUTER APPLY (
    SELECT TOP 1
        TRY_CONVERT(DECIMAL(5,2), dis.PERCENTAGE) AS PERCENTAGE
    FROM STAGING_TDC.dbo.STG_VTA_MySQL_Discounts dis
    WHERE ft.total_factura >= TRY_CONVERT(DECIMAL(12,2), dis.TOTAL_BILLING)
      AND ft.fecha >= TRY_CONVERT(DATE, dis.DATE_FROM)
      AND (
            dis.DATE_UNTIL IS NULL
            OR ft.fecha <= TRY_CONVERT(DATE, dis.DATE_UNTIL)
          )
    ORDER BY TRY_CONVERT(DECIMAL(5,2), dis.PERCENTAGE) DESC
) d;