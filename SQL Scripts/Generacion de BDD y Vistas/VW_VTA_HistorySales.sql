USE STAGING_TDC;
GO

CREATE OR ALTER VIEW dbo.VW_VTA_HistorySales AS

-- Las facturas con lineas rechazadas quedan registradas en VW_VTA_Rechazos
WITH VentaConMontos AS (
    SELECT
        vl.*,
        vl.cantidad * vl.precio_unitario AS monto_base_item
    FROM dbo.VW_VTA_HistorySales_Lineas vl
    WHERE vl.lineas_rechazadas_factura = 0
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
    -- Dentro de las vistas van angostas (menos memoria al ordenar); el paquete espera VARCHAR(255)
    CAST(vt.zipcode AS VARCHAR(255)) AS zipcode,
    CAST(vt.nro_factura AS VARCHAR(255)) AS nro_factura,
    vt.cantidad,

    TRY_CONVERT(DECIMAL(12,3), vt.cantidad) *
        (TRY_CONVERT(DECIMAL(12,3), prod.CM3) / 1000.0) AS litros_vendidos,

    vt.precio_unitario,
    vt.monto_base_item AS monto_base,

    ISNULL(d.PERCENTAGE, 0) AS porcentaje_descuento,

    -- Redondeo explicito: al guardar en DECIMAL(12,2) SSIS trunca en vez de redondear
    ROUND(vt.monto_base_item * (ISNULL(d.PERCENTAGE, 0) / 100.0), 2) AS monto_descuento,

    vt.monto_base_item - ROUND(
        vt.monto_base_item * (ISNULL(d.PERCENTAGE, 0) / 100.0), 2
    ) AS monto_final

FROM VentaConTotal vt

INNER JOIN dbo.VW_PRD_Products prod
    ON vt.id_producto = prod.PRODUCT_ID

OUTER APPLY (
    SELECT TOP 1
        TRY_CONVERT(DECIMAL(5,2), d.PERCENTAGE) AS PERCENTAGE
    FROM STAGING_TDC.dbo.STG_VTA_MySQL_Discounts d
    WHERE vt.total_factura >= TRY_CONVERT(DECIMAL(12,2), d.TOTAL_BILLING)
      AND vt.fecha_hora >= TRY_CONVERT(DATETIME2(0), d.DATE_FROM)
      AND (
            d.DATE_UNTIL IS NULL
            OR vt.fecha_hora <= TRY_CONVERT(DATETIME2(0), d.DATE_UNTIL)
          )
    ORDER BY TRY_CONVERT(DECIMAL(5,2), d.PERCENTAGE) DESC
) d;