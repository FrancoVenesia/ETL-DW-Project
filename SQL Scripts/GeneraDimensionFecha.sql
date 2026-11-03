DECLARE @vFechaDesde DATE = '2000-01-01';
DECLARE @vFechaHasta DATE = '2099-12-31';
--
WITH Fechas (Fecha) AS (
    SELECT @vFechaDesde
    UNION ALL
    SELECT DATEADD(d,1,Fecha)
    FROM Fechas
    WHERE Fecha < @vFechaHasta)

SELECT Fecha, 
        DAY(Fecha) AS Dia, 
        MONTH(Fecha) AS Mes, 
        DATENAME(MONTH,Fecha) AS NombreMes, 
        YEAR(Fecha) AS Año, 
        DATEPART(QQ,Fecha) AS Trimestre, 
        (DATEPART(QQ,Fecha) + 1) / 2 AS Semestre,
		DATEPART(DW,Fecha) AS DiaSemana, 
        DATENAME(DW,Fecha) AS NombreDiaSemana, 
		DATEPART(WK,Fecha) AS Semana, 
        DATENAME(DAYOFYEAR,Fecha) AS DiaAño,
        CASE WHEN h.HOLIDAY_DATE IS NOT NULL THEN 1 ELSE 0
        END AS es_feriado,
        h.HOLIDAY AS nombre_feriado
    FROM Fechas f
    LEFT JOIN STAGING_TDC.dbo.STG_HR_Holidays h
        ON f.Fecha = TRY_CONVERT(DATE, h.HOLIDAY_DATE, 103) -- llega como D/M/YYYY (locale es-AR del paquete)
    OPTION (MAXRECURSION 0)

