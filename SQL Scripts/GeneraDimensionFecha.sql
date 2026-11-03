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
        CAST(CHOOSE(MONTH(Fecha), N'Enero', N'Febrero', N'Marzo', N'Abril', N'Mayo', N'Junio', N'Julio', N'Agosto', N'Septiembre', N'Octubre', N'Noviembre', N'Diciembre') AS NVARCHAR(30)) AS NombreMes, 
        YEAR(Fecha) AS Año, 
        DATEPART(QQ,Fecha) AS Trimestre, 
        (DATEPART(QQ,Fecha) + 1) / 2 AS Semestre,
		-- Lunes = 1 y nombres en castellano sin depender del idioma ni de @@DATEFIRST del login
		(DATEPART(DW,Fecha) + @@DATEFIRST - 2) % 7 + 1 AS DiaSemana, 
        CAST(CHOOSE((DATEPART(DW,Fecha) + @@DATEFIRST - 2) % 7 + 1, N'Lunes', N'Martes', N'Miércoles', N'Jueves', N'Viernes', N'Sábado', N'Domingo') AS NVARCHAR(30)) AS NombreDiaSemana, 
		DATEPART(ISO_WEEK,Fecha) AS Semana, 
        DATENAME(DAYOFYEAR,Fecha) AS DiaAño,
        CASE WHEN h.HOLIDAY_DATE IS NOT NULL THEN 1 ELSE 0
        END AS es_feriado,
        h.HOLIDAY AS nombre_feriado
    FROM Fechas f
    LEFT JOIN STAGING_TDC.dbo.STG_HR_Holidays h
        ON f.Fecha = TRY_CONVERT(DATE, h.HOLIDAY_DATE, 103) -- llega como D/M/YYYY (locale es-AR del paquete)
    OPTION (MAXRECURSION 0)

