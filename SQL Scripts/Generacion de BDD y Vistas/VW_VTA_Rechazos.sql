USE STAGING_TDC;
GO

CREATE OR ALTER VIEW dbo.VW_VTA_Rechazos AS

-- Lineas que no llegan a fVenta por falta de cabecera de factura, de producto o de precio vigente.
-- Las demas lineas de esas facturas se rechazan como FACTURA_INCOMPLETA.
WITH Lineas AS (
    SELECT
        1 AS version_sistema,
        id_venta_sistema, fecha, id_cliente, id_empleado, id_producto, nro_factura, cantidad, motivo_rechazo
    FROM dbo.VW_VTA_HistorySales_Lineas
    WHERE lineas_rechazadas_factura > 0

    UNION ALL

    SELECT
        2 AS version_sistema,
        id_venta_sistema, fecha, id_cliente, id_empleado, id_producto, nro_factura, cantidad, motivo_rechazo
    FROM dbo.VW_VTA_MySQL_Lineas
    WHERE lineas_rechazadas_factura > 0
)

SELECT
    version_sistema,
    id_venta_sistema,
    fecha,
    id_cliente,
    id_empleado,
    id_producto,
    nro_factura,
    cantidad,

    ISNULL(motivo_rechazo, 'FACTURA_INCOMPLETA') AS Error_code,

    CASE motivo_rechazo
        WHEN 'PRODUCTO_INEXISTENTE' THEN 'id_producto'
        WHEN 'SIN_PRECIO_VIGENTE' THEN 'precio_unitario'
        ELSE 'nro_factura'
    END AS Error_column

FROM Lineas;
