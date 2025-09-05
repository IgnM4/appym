# Changelog

## [Unreleased]
- Replaced broken root `.gitignore` with standard rules and removed nested file.
- Removed committed credentials and added template files (`server/.env.example`, `desktop-app/app.properties.example`, `db-project/liquibase/liquibase.properties.example`).
- Added root `docker-compose.yml` to run Oracle XE and the Node API with configurable port.
- Updated backend to support `DB_URL` alias, retry/backoff for the Oracle pool and optional start without DB.
- Revised `scripts/publish_web.mjs` to rely solely on environment variables.
- Introduced minimal GitHub Actions workflow for Node and Maven builds with npm caching.
- Rewrote `README.md` with unified quickstart and variable documentation.
- Added `credenciales.txt` describing required secrets.
- Added MIT `LICENSE` and ignored exported CSV data.

### Migration
After pulling these changes:
```
git rm -r --cached **/node_modules **/dist **/build **/target
git rm -r --cached oracle_export
```

### Security
- Store credentials in environment files that are not checked into version control.
- Data under `oracle_export/` may contain sensitive information; keep it outside git.
