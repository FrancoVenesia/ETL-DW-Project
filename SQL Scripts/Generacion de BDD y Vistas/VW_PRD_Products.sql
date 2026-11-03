CREATE OR ALTER VIEW dbo.VW_PRD_Products AS
SELECT
    CAST(PRODUCT_ID AS INT) AS PRODUCT_ID,

    DETAIL AS producto,

    CASE
        WHEN DETAIL LIKE '%Beer%' THEN 'BEER'
        WHEN DETAIL LIKE '%Cola%' THEN 'COLA'
        WHEN LOWER(DETAIL) LIKE '%energy drink%' THEN 'ENERGY_DRINK'
        WHEN DETAIL LIKE '%Soda%' THEN 'SODA'
        ELSE 'JUICE'
    END AS rubro,

    PACKAGE AS presentacion,

    CASE
        WHEN PACKAGE LIKE '%can%' THEN 'CAN'
        ELSE 'BOTTLE'
    END AS tipo_envase,

    cm.CM3,

    CAST(cm.CM3 / 1000 AS DECIMAL(10,3)) AS contenido_litros,

    CASE
        WHEN DETAIL LIKE '%diet%' THEN 1
        ELSE 0
    END AS es_diet

FROM STAGING_TDC.dbo.STG_PRD_Products

CROSS APPLY (
    SELECT
        CAST(
            SUBSTRING(PACKAGE, 1, CHARINDEX(' ', PACKAGE) - 1)
            AS DECIMAL(10,3)
        ) *
        CASE
            WHEN PACKAGE LIKE '%LITER%' THEN 1000
            ELSE 1
        END AS CM3
) cm;