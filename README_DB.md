# Base de datos

## Prerrequisitos
- [Oracle XE 21c](https://www.oracle.com/database/technologies/xe-downloads.html) o contenedor Docker opcional.
- [SQLcl](https://www.oracle.com/database/technologies/appdev/sqlcl.html) y [Liquibase](https://www.liquibase.org/).
 - Variables de entorno: `LIQUI_URL`, `LIQUI_USER`, `LIQUI_PASS`.

Para un entorno desechable se puede usar Docker:
```bash
docker run -d --name oracle-xe -p 1521:1521 gvenzl/oracle-xe:21-slim
```

## Comandos Liquibase
Desde la raíz del repo:
```bash
liquibase --defaultsFile=db-project/liquibase/liquibase.properties status
liquibase --defaultsFile=db-project/liquibase/liquibase.properties update
liquibase --defaultsFile=db-project/liquibase/liquibase.properties updateSQL
liquibase --defaultsFile=db-project/liquibase/liquibase.properties history
liquibase --defaultsFile=db-project/liquibase/liquibase.properties rollbackCount 1
```

## Scripts operativos

En `db-project/scripts` se incluyen utilidades para pruebas rápidas:

- `demo_flow.sql` simula una compra y una venta afectando el stock.
- `check_operativo.sql` muestra saldos de inventario y movimientos recientes de compras y ventas.

## Troubleshooting
- **ORA-01031:** asegúrate de ejecutar con un usuario con privilegios suficientes o anteponer `SYS/clave AS SYSDBA`.
- **Permisos de carpeta:** el directorio `EXPORT_DIR` debe existir y ser accesible para el usuario de la BD.

> Nota: `EXPORT_DIR` se define en `ddl/13a_export_dir_sys.sql` y en Oracle debe apuntar a la carpeta donde se generarán los CSV.

## Portabilidad

El módulo de escritorio incorpora un repositorio `KpiRepository` con implementaciones para Oracle y PostgreSQL. Según la URL JDBC se selecciona automáticamente el motor y los perfiles Maven `postgres` y `mysql` agregan los controladores necesarios.
