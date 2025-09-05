# Desktop App

Aplicación JavaFX para visualizar KPIs de ventas.

## Configuración

Los valores de conexión se definen en `src/main/resources/app.properties`, el cual se genera con *resource filtering* de Maven. El perfil `oracle` está activo por defecto; para usar PostgreSQL o MySQL activar el perfil correspondiente (`-Ppostgres` o `-Pmysql`). Las variables de entorno `APP_DB_URL`, `APP_DB_USER`, `APP_DB_PASS` y `APP_EXPORT_DIR` pueden sobreescribir estos valores.

## Ejecutar

```bash
mvn -q javafx:run
```

## Características

- Consultas de ventas por producto basadas en relaciones entre boletas, detalles y productos para reflejar fielmente la estructura de la base de datos.
