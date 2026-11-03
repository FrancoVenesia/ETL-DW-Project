CREATE OR ALTER VIEW dbo.VW_VTA_MySQL_VentaActual AS

-- Las facturas con lineas rechazadas quedan registradas en VW_VTA_Rechazos
WITH LineasConProductoCliente AS (
    SELECT
        lp.*,
        c.zipcode,
        prod.CM3
    FROM dbo.VW_VTA_MySQL_Lineas lp
    -- HASH: sin la pista el optimizador recorre los clientes por cada linea
    LEFT HASH JOIN dbo.VW_COM_Clientes c
        ON lp.id_cliente = c.id_cliente
    INNER JOIN dbo.VW_PRD_Products prod
        ON lp.id_producto = prod.PRODUCT_ID
    WHERE lp.lineas_rechazadas_factura = 0
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

    -- Redondeo explicito: al guardar en DECIMAL(12,2) SSIS trunca en vez de redondear
    ROUND(monto_base * (ISNULL(d.PERCENTAGE, 0) / 100.0), 2) AS monto_descuento,

    monto_base - ROUND(
        monto_base * (ISNULL(d.PERCENTAGE, 0) / 100.0), 2
    ) AS monto_final

FROM FacturasConTotal ft

OUTER APPLY (
    SELECT TOP 1
        TRY_CONVERT(DECIMAL(5,2), dis.PERCENTAGE) AS PERCENTAGE
    FROM STAGING_TDC.dbo.STG_VTA_MySQL_Discounts dis
    WHERE ft.total_factura >= TRY_CONVERT(DECIMAL(12,2), dis.TOTAL_BILLING)
      AND ft.fecha_hora >= TRY_CONVERT(DATETIME2(0), dis.DATE_FROM)
      AND (
            dis.DATE_UNTIL IS NULL
            OR ft.fecha_hora <= TRY_CONVERT(DATETIME2(0), dis.DATE_UNTIL)
          )
    ORDER BY TRY_CONVERT(DECIMAL(5,2), dis.PERCENTAGE) DESC
) d;