@echo off
setlocal
cd /d "%~dp0"

echo === Docker compose ===
docker compose config || goto :eof
docker compose up -d || goto :eof

echo === Esperando Oracle (25s) ===
timeout /t 25 >nul
docker exec app-oracle-xe-1 bash -lc "sqlplus -L -s APP_PYME/app_pyme_pass@localhost:1521/XEPDB1 @/dev/null" || echo Aviso: Oracle aun iniciando.

echo === API (monorepo, workspace api) ===
start "API" powershell -NoExit -Command ^
  "cd '%CD%'; npm run dev:api"
endlocal
