CREATE OR ALTER VIEW dbo.VW_VTA_HistorySales AS

WITH VentasTipadas AS (
    SELECT 
        TRY_CONVERT(INT, hs.ID) AS id_venta_sistema,
        TRY_CONVERT(VARCHAR(255), hs.BILLING_ID) AS nro_factura,
        TRY_CONVERT(DATE, hs.SALE_DATE) AS fecha,
        TRY_CONVERT(INT, hs.CUSTOMER_ID) AS id_cliente,
        TRY_CONVERT(INT, hs.EMPLOYEE_ID) AS id_empleado,
        TRY_CONVERT(INT, hs.PRODUCT_ID) AS id_producto,
        TRY_CONVERT(INT, hs.QUANTITY) AS cantidad
    FROM STAGING_TDC.dbo.STG_VTA_HistorySales hs
),

VentaConPrecio AS (
    SELECT 
        vt.*,
        TRY_CONVERT(DECIMAL(12,2), p.PRICE) AS precio_unitario
    FROM VentasTipadas vt
    OUTER APPLY (
        SELECT TOP 1 
            p.PRICE
        FROM STAGING_TDC.dbo.STG_VTA_MySQL_Prices p
        WHERE TRY_CONVERT(INT, p.PRODUCT_ID) = vt.id_producto
          AND TRY_CONVERT(DATE, p.PRICE_DATE) <= vt.fecha
        ORDER BY TRY_CONVERT(DATE, p.PRICE_DATE) DESC
    ) p
),

VentaConMontos AS (
    SELECT
        vp.*,
        vp.cantidad * vp.precio_unitario AS monto_base_item
    FROM VentaConPrecio vp
    WHERE vp.precio_unitario IS NOT NULL
),

VentaConTotal AS (
    SELECT
        vm.*,
        SUM(vm.monto_base_item) OVER (PARTITION BY vm.nro_factura) AS total_factura
    FROM VentaConMontos vm
)

SELECT 
    1 AS version_sistema,
    vt.id_venta_sistema,
    vt.fecha,
    vt.id_cliente,
    vt.id_empleado,
    vt.id_producto,
    c.zipcode,
    vt.nro_factura,
    vt.cantidad,

    TRY_CONVERT(DECIMAL(12,3), vt.cantidad) *
        (TRY_CONVERT(DECIMAL(12,3), prod.CM3) / 1000.0) AS litros_vendidos,

    vt.precio_unitario,
    vt.monto_base_item AS monto_base,

    ISNULL(d.PERCENTAGE, 0) AS porcentaje_descuento,

    vt.monto_base_item * (ISNULL(d.PERCENTAGE, 0) / 100.0) AS monto_descuento,

    vt.monto_base_item - (
        vt.monto_base_item * (ISNULL(d.PERCENTAGE, 0) / 100.0)
    ) AS monto_final

FROM VentaConTotal vt

LEFT JOIN DW_TDC.dbo.dCliente c
    ON vt.id_cliente = c.id_cliente

INNER JOIN dbo.VW_PRD_Products prod
    ON vt.id_producto = prod.PRODUCT_ID

OUTER APPLY (
    SELECT TOP 1
        TRY_CONVERT(DECIMAL(5,2), d.PERCENTAGE) AS PERCENTAGE
    FROM STAGING_TDC.dbo.STG_VTA_MySQL_Discounts d
    WHERE vt.total_factura >= TRY_CONVERT(DECIMAL(12,2), d.TOTAL_BILLING)
      AND vt.fecha >= TRY_CONVERT(DATE, d.DATE_FROM)
      AND (
            d.DATE_UNTIL IS NULL
            OR vt.fecha <= TRY_CONVERT(DATE, d.DATE_UNTIL)
          )
    ORDER BY TRY_CONVERT(DECIMAL(5,2), d.PERCENTAGE) DESC
) d;