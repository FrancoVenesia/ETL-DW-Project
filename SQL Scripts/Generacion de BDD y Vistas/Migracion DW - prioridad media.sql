-- Lleva un DW_TDC creado con la version anterior de "Generacion de DW.sql" a la actual.
-- Alternativa: borrar DW_TDC, correr "Generacion de DW.sql" y ejecutar el paquete.
USE DW_TDC;
GO

CREATE SCHEMA err;
GO

ALTER SCHEMA err TRANSFER dbo.ERROR_dCliente_dGeografia;
ALTER SCHEMA err TRANSFER dbo.ERROR_fVenta;
GO

DECLARE @pk SYSNAME = (
    SELECT name FROM sys.key_constraints
    WHERE type = 'PK' AND parent_object_id = OBJECT_ID('err.ERROR_dCliente_dGeografia')
);
IF @pk IS NOT NULL
    EXEC ('ALTER TABLE err.ERROR_dCliente_dGeografia DROP CONSTRAINT ' + @pk);

ALTER TABLE err.ERROR_dCliente_dGeografia ALTER COLUMN id_cliente INTEGER NULL;
ALTER TABLE err.ERROR_dCliente_dGeografia ADD fecha_carga DATETIME DEFAULT GETDATE();

ALTER TABLE err.ERROR_fVenta ADD version_sistema VARCHAR(255), fecha_carga DATETIME DEFAULT GETDATE();
GO
