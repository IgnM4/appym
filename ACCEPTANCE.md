# Acceptance Criteria

- `cd db-project && liquibase status` ⇒ 0 pendientes tras aplicar 019 y 020.
- `liquibase tag list` incluye `baseline-2025-08-16`; `rollbackToTag baseline-2025-08-16` revierte objetos 014–018; `update` los reaplica sin error.
- `cd desktop-app && mvn -q javafx:run` arranca la UI y permite consultar y exportar CSV sin stacktrace.
- `cd web-app && firebase deploy` publica y la web muestra gráficos y tablas con datos.
- `scripts/publish_web.bat` genera `latest.json`, copia CSVs y despliega en Firebase.
- `db-project/.vscode/tasks.json` ejecuta correctamente cada tarea en Windows.
