-- Agrega a un DW_TDC existente la tabla de auditoria de "Generacion de DW.sql".
USE DW_TDC;
GO

CREATE SCHEMA etl;
GO

CREATE TABLE etl.Ejecucion (
    id_ejecucion INTEGER IDENTITY(1,1) PRIMARY KEY,
    fecha_fin DATETIME DEFAULT GETDATE(),
    filas_fVenta INTEGER,
    filas_fVenta_desconocidas INTEGER,
    monto_fVenta DECIMAL(14,2),
    filas_fStock INTEGER,
    filas_dCliente INTEGER,
    errores_fVenta INTEGER,
    errores_dCliente INTEGER
);
GO
