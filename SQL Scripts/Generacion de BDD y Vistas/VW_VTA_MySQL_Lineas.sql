USE STAGING_TDC;
GO

CREATE OR ALTER VIEW dbo.VW_VTA_MySQL_Lineas AS

WITH LineasVenta AS (
    SELECT
        TRY_CONVERT(INT, bd.BILLING_ID) AS id_venta_sistema,
        TRY_CONVERT(VARCHAR(20), bd.BILLING_ID) AS nro_factura,
        TRY_CONVERT(DATE, b.BILLING_DATE) AS fecha,
        TRY_CONVERT(DATETIME2(0), b.BILLING_DATE) AS fecha_hora,
        TRY_CONVERT(INT, b.CUSTOMER_ID) AS id_cliente,
        TRY_CONVERT(INT, b.EMPLOYEE_ID) AS id_empleado,
        TRY_CONVERT(INT, bd.PRODUCT_ID) AS id_producto,
        TRY_CONVERT(INT, bd.QUANTITY) AS cantidad,
        CASE WHEN b.BILLING_ID IS NULL THEN 0 ELSE 1 END AS tiene_cabecera,
        c.zipcode
    FROM STAGING_TDC.dbo.STG_VTA_MySQL_BillingDetail bd
    -- LEFT JOIN: el origen trae detalles cuya factura no existe en billing
    LEFT JOIN STAGING_TDC.dbo.STG_VTA_MySQL_Billing b
        ON b.BILLING_ID = bd.BILLING_ID
    -- El cliente se busca aca, sobre las filas de staging: despues de las funciones de ventana
    -- el optimizador elige recorrer los clientes por cada linea
    LEFT JOIN dbo.VW_COM_Clientes c
        ON c.id_cliente = TRY_CONVERT(INT, b.CUSTOMER_ID)
),

LineasConPrecio AS (
    SELECT
        lv.*,
        p.precio AS precio_unitario
    FROM LineasVenta lv
    LEFT JOIN dbo.VW_VTA_Precios p
        ON p.id_producto = lv.id_producto
       AND lv.fecha_hora >= p.vigente_desde
       AND (p.vigente_hasta IS NULL OR lv.fecha_hora < p.vigente_hasta)
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
