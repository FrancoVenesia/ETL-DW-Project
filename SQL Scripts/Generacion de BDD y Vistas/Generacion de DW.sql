CREATE DATABASE DW_TDC;
GO

USE DW_TDC;
GO

CREATE TABLE dTiempo (
    fecha DATE PRIMARY KEY,
    dia TINYINT,
    mes TINYINT,
    trimestre TINYINT,
    semestre TINYINT,
    anio SMALLINT,
    dia_semana TINYINT,
    nombre_dia_semana VARCHAR(255),
    nombre_mes VARCHAR(255),
    es_feriado BIT,
    nombre_feriado VARCHAR(255),
    semana TINYINT,
    dia_anio SMALLINT

);

CREATE TABLE dGeografia (
    zipcode VARCHAR(255) PRIMARY KEY,
    region VARCHAR(255),
    state VARCHAR(255),
    city VARCHAR(255)
);

CREATE TABLE dProducto (
    id_producto INTEGER PRIMARY KEY,
    producto VARCHAR(255),
    rubro VARCHAR(255),
    presentacion VARCHAR(255),
    tipo_envase VARCHAR(255),
    contenido_litros DECIMAL(10,3),
    es_diet BIT
);

CREATE TABLE dCliente (
    id_cliente INTEGER PRIMARY KEY,
    zipcode VARCHAR(255),
    nombre_completo VARCHAR(255),
    fecha_nacimiento DATE,
    tipo_cliente VARCHAR(255),

    CONSTRAINT fk_dCliente_zipcode_dGeografia
        FOREIGN KEY (zipcode) REFERENCES dGeografia(zipcode)
);


CREATE TABLE dEmpleado (
    id_empleado INTEGER PRIMARY KEY,
    nombre_completo VARCHAR(255),
    genero VARCHAR(255),
    categoria VARCHAR(255),
    fecha_ingreso DATE,
    fecha_nacimiento DATE,
    nivel_educacion VARCHAR(255)
);

CREATE TABLE fVenta (
    id_venta INTEGER IDENTITY(1,1) PRIMARY KEY,
    version_sistema TINYINT,
    id_venta_sistema INTEGER,
    fecha DATE,
    id_cliente INTEGER,
    id_empleado INTEGER,
    id_producto INTEGER,
    zipcode VARCHAR(255),
    nro_factura VARCHAR(255),
    cantidad INTEGER,
    litros_vendidos DECIMAL(12,3),
    precio_unitario DECIMAL(12,2),
    monto_base DECIMAL(12,2),
    porcentaje_descuento DECIMAL(5,2),
    monto_descuento DECIMAL(12,2),
    monto_final DECIMAL(12,2),

    CONSTRAINT fk_fVenta_fecha_dTiempo
        FOREIGN KEY (fecha) REFERENCES dTiempo(fecha),

    CONSTRAINT fk_fVenta_cliente_dCliente
        FOREIGN KEY (id_cliente) REFERENCES dCliente(id_cliente),

    CONSTRAINT fk_fVenta_empleado_dEmpleado
        FOREIGN KEY (id_empleado) REFERENCES dEmpleado(id_empleado),

    CONSTRAINT fk_fVenta_producto_dProducto
        FOREIGN KEY (id_producto) REFERENCES dProducto(id_producto),

    CONSTRAINT fk_fVenta_zipcode_dGeografia
        FOREIGN KEY (zipcode) REFERENCES dGeografia(zipcode)
);

CREATE TABLE fStock (
    id_stock INTEGER PRIMARY KEY,
    fecha DATE,
    hora TIME,
    id_producto INTEGER,
    variacion INTEGER,
    

    CONSTRAINT fk_fStock_fecha_dTiempo
        FOREIGN KEY (fecha) REFERENCES dTiempo(fecha),

    CONSTRAINT fk_fStock_producto_dProducto
        FOREIGN KEY (id_producto) REFERENCES dProducto(id_producto)
);

GO

-- Tablas de error: sin PK (un registro puede fallar mas de una vez) y con fecha de carga
CREATE SCHEMA err;
GO

CREATE TABLE err.ERROR_dCliente_dGeografia (
    id_cliente INTEGER,
    nombre_completo VARCHAR(255),
    fecha_nacimiento VARCHAR(255),
    tipo_cliente VARCHAR(255),
    zipcode VARCHAR(255),
    Error_code VARCHAR(255),
    Error_column VARCHAR(255),
    fecha_carga DATETIME DEFAULT GETDATE()
);

CREATE TABLE err.ERROR_fVenta (
    id_venta VARCHAR(255),
    fecha VARCHAR(255),
    id_cliente VARCHAR(255),
    id_empleado VARCHAR(255),
    id_producto VARCHAR(255),
    zipcode VARCHAR(255),
    nro_factura VARCHAR(255),
    cantidad VARCHAR(255),
    litros_vendidos VARCHAR(255),
    precio_unitario VARCHAR(255),
    monto_base VARCHAR(255),
    porcentaje_descuento VARCHAR(255),
    monto_descuento VARCHAR(255),
    monto_final VARCHAR(255),
    Error_code VARCHAR(255),
    Error_column VARCHAR(255),
    version_sistema VARCHAR(255),
    fecha_carga DATETIME DEFAULT GETDATE()
);
GO

-- Una fila por corrida del paquete (la inserta la tarea "Registrar ejecucion")
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
