# AplicacionPyme

Monorepo para una PyME de distribución de gas. Incluye:

- **db-project** – scripts Oracle y changelogs Liquibase.
- **desktop-app** – aplicación JavaFX para refrescar KPIs y exportar CSV.
- **server** – API Node.js/Express.
- **web-app** – sitio estático servido con Firebase Hosting.

## Prerrequisitos
- Java 17+ y Maven
- Node.js 18+
- SQLcl y Liquibase
- Oracle XE 21c o acceso a un servidor Oracle (Instant Client para oracledb)

## Quickstart
1. Levantar la base de datos (opcional):
   ```bash
   docker compose up -d oracle-xe
   ```
2. Definir credenciales para Liquibase:
   ```bash
   export LIQUI_URL=jdbc:oracle:thin:@//localhost:1521/XEPDB1
   export LIQUI_USER=app_user
   export LIQUI_PASS=change_me
   ```
   ```bash
   liquibase --defaultsFile=db-project/liquibase/liquibase.properties.example update
   ```
3. Backend API:
   ```bash
   cd server
    cp .env.example .env  # editar con tus valores
   npm ci
   npm run dev           # o npm run build && npm start
   ```
4. Aplicación de escritorio:
   ```bash
   mvn -q -f desktop-app/pom.xml javafx:run
   ```
5. Publicar CSV y servir la web:
   ```bash
   node scripts/publish_web.mjs
   cd web-app
   npm ci
   firebase serve
   ```

## Variables de entorno
| Componente | Variables |
|------------|-----------|
| Backend Node (`server/.env`) | `API_PORT` (o `PORT`), `DB_USER`, `DB_PASSWORD`, `DB_CONNECT_STRING` **o** `DB_URL` |
| JDBC/Desktop (`desktop-app/app.properties`) | `APP_DB_URL`, `APP_DB_USER`, `APP_DB_PASSWORD` |
| Liquibase y scripts | `LIQUI_URL`, `LIQUI_USER`, `LIQUI_PASS` |
| Scripts | `SQLCL_BIN`, `EXPORT_DIR` |
| Docker Compose | `ORACLE_PASSWORD`, `DB_USER`, `DB_PASSWORD`, `API_PORT` |

El backend acepta `DB_URL` como alias de `DB_CONNECT_STRING` para compatibilidad.

Consulta `credenciales.txt` para un listado de todas las variables sensibles.

## Producción
- Ejecutar `firebase deploy` para publicar la web.
- Cambiar todas las credenciales por valores seguros.
- Asegurarse de que Oracle Instant Client esté instalado si se ejecuta fuera de Docker.
- Verificar puertos abiertos (`1521`, `5500`, `4000`).
- Controlar el tamaño de los CSV y permisos del directorio `EXPORT_DIR`.

## Limpieza de artefactos versionados
Si se llegó a commitear `node_modules`, `dist`, `build` o `target`:
```bash
git rm -r --cached **/node_modules **/dist **/build **/target
git commit -m "chore: remove build artifacts"
```

Para dejar de rastrear datos exportados en `oracle_export/`:
```bash
git rm -r --cached oracle_export
git add .
git commit -m "chore: stop tracking exported data"
```

El contenido de `oracle_export/` puede ser sensible. Mantén estos datos fuera del control de versiones o utiliza un repositorio/artefacto separado.

## Otros
- `docker-compose.yml` levanta la API en el puerto `${API_PORT:-4000}`.
- `db-project/docker/docker-compose.yml.example` levanta únicamente Oracle XE para pruebas aisladas.

## Troubleshooting

- **No se puede conectar a la BD:** revisa `DB_USER`, `DB_PASSWORD` y `DB_CONNECT_STRING`/`DB_URL`. Si usas desarrollo local, puedes arrancar con `ALLOW_START_WITHOUT_DB=true`.
- **Puerto en uso:** la API usa `API_PORT` (por defecto 4000). Cambia la variable o libera el puerto.
- **Falta Oracle Instant Client:** instala el Instant Client si te conectas a una BD remota sin Docker.
# pyme
