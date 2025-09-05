# DB Project – Compras/Ventas (PyME Subdistribuidores)

## Requisitos
- Oracle XE 21c (local o Docker) con PDB `XEPDB1`
- SQLcl (o SQL*Plus)
- VS Code

## Opciones de entorno

### A) Docker (recomendado)

```bash
cd docker
docker compose up -d
# Usuario APP_PYME y PDB XEPDB1 quedan listos
Conexión: APP_PYME/change_me@localhost:1521/XEPDB1

B) Local

Instala Oracle XE 21c y SQLcl.

En VS Code: Terminal > Run Task > DB: create app user (SYS).

Despliegue

Renombra vscode/ a .vscode/.

Ajusta .vscode/settings.json con la ruta de sqlcl y la db.connection.

Ejecuta Terminal > Run Task > DB: run_all (SQLcl).

Demo end-to-end

Terminal > Run Task > DB: demo flow (compras→ventas)
Valida con:

SELECT * FROM v_ventas_diarias ORDER BY dia DESC;
SELECT * FROM v_compras_vs_ventas_dia ORDER BY dia DESC;
SELECT * FROM v_stock_bajo_minimo;
Reset rápido de esquema

Terminal > Run Task > DB: reset schema (drop→run_all)

Estructura

ddl/ tablas, constraints, índices, vistas, semillas, triggers

scripts/run_all.sql orquesta la creación

scripts/demo_flow.sql prueba completa

docker/docker-compose.yml Oracle XE listo

Notas

IVA parametrizado en parametro_sistema('IVA').

Contraseñas de usuarios deben ir hasheadas en la app (BCrypt/Argon2).

Borrado lógico en maestros con activo CHAR(1).

Roadmap (sprint siguiente)

Liquibase (migraciones controladas).

MV para KPIs y scheduler de refresh.

Auditoría fina por LOG_CAMBIOS (triggers por tabla).

Multi-sucursal y códigos de barras.
---

## 7) ¿Cómo lo ejecutas ahora?

1) **Si vas con Docker**  
- `docker compose up -d` dentro de `docker/`.  
- En VS Code: **DB: run_all (SQLcl)** → **DB: demo flow**.

2) **Si vas local**  
- **DB: create app user (SYS)** (te pedirá la clave de SYS).  
- **DB: run_all (SQLcl)** → **DB: demo flow**.

Listo. Con esto tienes **entorno, automatización y demo funcional**.  
¿Seguimos con **Liquibase** y un set de **CSV de importación** (productos, proveedores, stock inicial) para acelerar carga real?

### KPI diarios
- Ejecutar ahora:
  ```bash
  sql -thin APP_PYME/change_me@//localhost:1521/XEPDB1 @"scripts/run_export_now.sql"
Archivos:

C:\oracle_export\ventas_hoy_YYYYMMDD.csv

C:\oracle_export\ventas_prod_ult7d_YYYYMMDD.csv

Chequear jobs y logs
sql -thin APP_PYME/change_me@//localhost:1521/XEPDB1 @"scripts/check_scheduler.sql"

---

# 6) (Opcional) Autotuning y endurecimiento

- Si quieres que el **rewrite** de consultas use MVs automáticamente en sesiones futuras:
  ```sql
  -- como SYSTEM
  ALTER SYSTEM SET query_rewrite_enabled = TRUE SCOPE=BOTH;
Revisa que APP_PYME tenga solo los privilegios que necesita (CREATE VIEW/PROCEDURE/JOB/MATERIALIZED VIEW y RW sobre EXPORT_DIR).

7) Git (versiona el hito)

git add ddl/* liquibase/* scripts/* .vscode/*
git commit -m "KPIs: MVs, vistas, exports CSV + scheduler + tasks VSCode"
git tag -a db-kpi-exports-2025-08-16 -m "Hito KPIs y export diario"
