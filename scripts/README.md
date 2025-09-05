# Scripts

Scripts for database exports and demos rely on certain environment variables.

## `publish_web`

The `publish_web` scripts export KPI data via SQLcl and copy CSV files into the web app.

Required variables:

- `SQLCL_BIN`: path to the `sql` executable from Oracle SQLcl.
- `LIQUI_USER`, `LIQUI_PASS`, `LIQUI_URL`: credentials used by SQLcl.
- `EXPORT_DIR`: directory containing exported `.csv` files.

## `run_demo_venta`

Runs a SQL*Plus demo against the database.

Optional variables (defaults shown):

- `DB_USER` (`APP_PYME`)
- `DB_PASSWORD` (`change_me`)
- `DB_CONNECT_STRING` (`//localhost:1521/XEPDB1`)

Copy `.env.example` to `.env` and adjust values as needed.
