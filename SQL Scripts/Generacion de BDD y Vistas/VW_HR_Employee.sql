CREATE OR ALTER VIEW dbo.VW_HR_Employee AS

SELECT
        TRY_CONVERT(INT, EMPLOYEE_ID) AS id_empleado,
        FULL_NAME AS nombre_completo,
        GENDER AS genero,
        CATEGORY AS categoria,
        -- Estilo 101 (MM/DD/YYYY) explicito: no depende del idioma del login
        TRY_CONVERT(DATE, EMPLOYMENT_DATE, 101) AS fecha_ingreso,
        TRY_CONVERT(DATE, BIRTH_DATE, 101) AS fecha_nacimiento,


        DATEDIFF(YEAR, TRY_CONVERT(DATE, BIRTH_DATE, 101), GETDATE()) AS edad,

        EDUCATION_LEVEL AS nivel_educacion
    FROM STAGING_TDC.dbo.STG_HR_Employee
    WHERE TRY_CONVERT(INT, EMPLOYEE_ID) IS NOT NULL;