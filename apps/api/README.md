# API

Copy `.env.example` to `.env` and set the following variables:

- `PORT`: HTTP port for the API (default 4000).
- `DB_USER`, `DB_PASSWORD`, `DB_CONNECT`: credentials and connection string for the Oracle DB.

PowerShell scripts like `migrate.ps1` and `db-check.ps1` rely on these values for database access.
