# ETL y Data Warehouse – The Drinking Company

Trabajo práctico final de Bases de Datos 2 (TUIA). Un paquete de SSIS lleva los datos de las fuentes
operacionales a una base de staging, los transforma con vistas de SQL y los carga en un Data
Warehouse dimensional que alimenta el tablero de Power BI.

**[Ver capturas del proyecto en ejecución →](CAPTURAS.md)** (modelo del DW, paquete de SSIS y
paneles de Power BI)

```
Fuentes (SQL Server, MySQL, XML, XLS, TXT)
   │  SSIS: Staging Ingest
   ▼
STAGING_TDC  ── vistas VW_* (limpieza, precios, descuentos, rechazos)
   │  SSIS: DW Load
   ▼
DW_TDC  (dTiempo, dGeografia, dCliente, dEmpleado, dProducto, fVenta, fStock)
   │
   ▼
Power BI (Empresa TDC.pbix)
```

## Contenido del repositorio

| Carpeta / archivo | Qué tiene |
|---|---|
| `SSIS_Packages/` | Proyecto de Integration Services con `Package_Master.dtsx` |
| `Integration Services Project1.slnx` | Solución de Visual Studio |
| `SQL Scripts/Generacion de BDD y Vistas/` | Creación de STAGING_TDC y DW_TDC, vistas y migraciones |
| `SQL Scripts/GeneraDimensionFecha.sql` | Consulta que arma dTiempo (la misma que usa el paquete) |
| `SQL Scripts/Busqueda de inconsistencias/` | Consultas de control y registro de inconsistencias encontradas |
| `Fuentes de Datos TP Final-20260517/` | Archivos fuente; los respaldos de bases van comprimidos en `.zip` |
| `Documentacion/` | Enunciado (con las credenciales de la cátedra ocultas) y capturas del proyecto |
| `CAPTURAS.md` | Capturas del proyecto en ejecución |
| `Empresa TDC.pbix` | Tablero de Power BI |
| `Empresa TDC.pbip` y carpetas `Empresa TDC.Report` / `.SemanticModel` | El mismo tablero como proyecto de Power BI (modelo y reporte en texto, versionables) |

## Requisitos

- SQL Server (alcanza con Express) y SQL Server Management Studio.
- Visual Studio 2022 con la extensión SQL Server Integration Services Projects.
- Microsoft OLE DB Driver for SQL Server (`MSOLEDBSQL`).
- Microsoft Access Database Engine (ACE OLEDB 16.0) para leer los Excel.
- Driver ODBC de MySQL y un DSN de sistema de 64 bits llamado `sales` que apunte a la base `sales`
  de la cátedra (los datos de conexión están en el campus).
- Power BI Desktop.

## Puesta en marcha

1. Descomprimir `Fuentes de Datos TP Final-20260517/Area Comercializacion/TDChistorySales_2019.zip`
   y restaurar el `.bak` en SQL Server con el nombre `TDChistorySales`.
2. Crear el DSN ODBC `sales`.
3. En SSMS, ejecutar `Generacion de Staging.sql` y `Generacion de DW.sql`.
4. Crear las vistas en este orden (cada script ya hace `USE STAGING_TDC`):
   `VW_COM_Regions`, `VW_COM_Clientes`, `VW_HR_Employee`, `VW_PRD_Products`, `VW_PRD_Stock`,
   `VW_VTA_Precios`, `VW_VTA_HistorySales_Lineas`, `VW_VTA_MySQL_Lineas`, `VW_VTA_HistorySales`,
   `VW_VTA_MySQL_VentaActual`, `VW_VTA_Rechazos`.
5. Abrir la solución y, en los parámetros de `Package_Master.dtsx`, ajustar:
   - `RutaFuentes`: carpeta `Fuentes de Datos TP Final-20260517` (sin barra al final).
   - `ServidorSQL`: instancia de SQL Server (por defecto `.\SQLEXPRESS`).
6. Ejecutar `Package_Master.dtsx`. Cada corrida vacía y recarga el DW completo.

Si ya tenías un DW_TDC creado con una versión anterior, en lugar del paso 3 para el DW podés correr
las migraciones `Migracion DW - prioridad media.sql` y `Migracion DW - auditoria.sql`, o borrar la
base y crearla de nuevo.

## El paquete

**Staging Ingest**: vacía las tablas `STG_*` y copia las fuentes tal cual, todo como texto.

**DW Load**:

1. *Truncado y Borrado DW*: vacía el DW y crea los miembros desconocidos (-1) de `dGeografia`,
   `dCliente` y `dEmpleado`.
2. *Importar dimensiones Independientes*: `dTiempo`, `dGeografia`, `dEmpleado`, `dProducto`.
3. *Importar dimensiones Dependientes*: `dCliente` (valida el zipcode contra `dGeografia`).
4. *Materializar ventas*: calcula una sola vez, y de a una, las vistas de ventas y de rechazos en
   las tablas `TRF_VTA_HistorySales`, `TRF_VTA_MySQL_VentaActual` y `TRF_VTA_Rechazos` de staging.
   Si el data flow abriera las vistas en paralelo, cada una reservaría memoria para ordenar y en
   una PC con poca memoria libre se traban esperándose entre sí.
5. *Importar Hechos a DW*: `fVenta` (valida cliente y empleado) y `fStock`.
6. *Cargar ventas con miembros desconocidos*: carga con -1 las ventas cuyo cliente o empleado no
   existe en las dimensiones.
7. *Registrar rechazos*: guarda en `err.ERROR_fVenta` las líneas que no llegan a `fVenta` y completa
   el motivo de cada error.
8. *Registrar ejecucion*: deja una fila con los totales de la corrida en `etl.Ejecucion`.

## Reglas de limpieza y transformación

- **Zipcodes**: los XML de clientes traen zipcodes sin el cero inicial; se completan a 5 dígitos.
- **Fechas**: se convierten con estilo explícito (101 para MM/DD/YYYY, 103 para los feriados que llegan
  como D/M/YYYY) para no depender del idioma del login ni del locale es-AR del paquete.
- **Precios**: cada precio rige desde su fecha y hora (`PRICE_DATE`) hasta el siguiente del mismo
  producto (`VW_VTA_Precios`).
- **Descuentos**: se aplica el de mayor porcentaje entre los vigentes a la fecha y hora de la factura
  cuyo monto mínimo cubre el total de la factura.
- **Facturas incompletas**: si una línea no tiene cabecera, producto o precio vigente, se rechaza la
  factura entera, porque sin esa línea no se puede calcular el total ni el descuento.
- **Montos**: se redondean a 2 decimales en las vistas (SSIS trunca al guardar en `DECIMAL(12,2)`).
- **Rubros**: Root Beer y Birch Beer son gaseosas sin alcohol y van a SODA; BEER queda para las cervezas.
- **dTiempo**: nombres de días y meses en castellano, lunes = 1 y semana ISO.

## Errores y auditoría

| Tabla | Contenido |
|---|---|
| `err.ERROR_fVenta` | Líneas de venta que no entran a `fVenta` o entran con -1. `Error_code`: `SIN_PRECIO_VIGENTE`, `PRODUCTO_INEXISTENTE`, `FACTURA_SIN_CABECERA`, `FACTURA_INCOMPLETA`, `CLIENTE_INEXISTENTE`, `EMPLEADO_INEXISTENTE` |
| `err.ERROR_dCliente_dGeografia` | Clientes que no entran a `dCliente`: `ZIPCODE_INEXISTENTE`, `FECHA_NACIMIENTO_INVALIDA` |
| `etl.Ejecucion` | Una fila por corrida con filas cargadas, ventas con miembros desconocidos, monto total y errores |

Las inconsistencias detectadas en las fuentes están detalladas en
`SQL Scripts/Busqueda de inconsistencias/Registro de Inconsistencias.xlsx`.
