CREATE OR ALTER VIEW dbo.VW_VTA_HistorySales_Lineas AS

WITH VentasTipadas AS (
    SELECT
        TRY_CONVERT(INT, hs.ID) AS id_venta_sistema,
        TRY_CONVERT(VARCHAR(255), hs.BILLING_ID) AS nro_factura,
        TRY_CONVERT(DATE, hs.SALE_DATE) AS fecha,
        TRY_CONVERT(DATETIME2(0), hs.SALE_DATE) AS fecha_hora,
        TRY_CONVERT(INT, hs.CUSTOMER_ID) AS id_cliente,
        TRY_CONVERT(INT, hs.EMPLOYEE_ID) AS id_empleado,
        TRY_CONVERT(INT, hs.PRODUCT_ID) AS id_producto,
        TRY_CONVERT(INT, hs.QUANTITY) AS cantidad
    FROM STAGING_TDC.dbo.STG_VTA_HistorySales hs
),

VentaConPrecio AS (
    SELECT
        vt.*,
        p.precio AS precio_unitario
    FROM VentasTipadas vt
    LEFT JOIN dbo.VW_VTA_Precios p
        ON p.id_producto = vt.id_producto
       AND vt.fecha_hora >= p.vigente_desde
       AND (p.vigente_hasta IS NULL OR vt.fecha_hora < p.vigente_hasta)
),

VentaConMotivo AS (
    SELECT
        vp.*,
        CASE
            WHEN NOT EXISTS (SELECT 1 FROM dbo.VW_PRD_Products prod WHERE prod.PRODUCT_ID = vp.id_producto)
                THEN 'PRODUCTO_INEXISTENTE'
            WHEN vp.precio_unitario IS NULL
                THEN 'SIN_PRECIO_VIGENTE'
        END AS motivo_rechazo
    FROM VentaConPrecio vp
)

-- Una linea rechazada invalida toda su factura: sin ella no se puede calcular el total ni el descuento
SELECT
    vm.*,
    COUNT(vm.motivo_rechazo) OVER (PARTITION BY vm.nro_factura) AS lineas_rechazadas_factura
FROM VentaConMotivo vm;
