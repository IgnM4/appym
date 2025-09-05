@echo off
setlocal
set SQLCL=%SQLCL_BIN%
set EXPORT_DIR=%EXPORT_DIR%
set DATA_DIR=%~dp0..\web-app\public\data

if defined LIQUI_USER if defined LIQUI_PASS if defined LIQUI_URL (
  echo BEGIN pr_export_kpis_daily; END; / | %SQLCL% %LIQUI_USER%/%LIQUI_PASS%@%LIQUI_URL%
) else (
  echo LIQUI_URL/LIQUI_USER/LIQUI_PASS no definidos & goto end
)

for %%F in ("%EXPORT_DIR%\ventas_hoy*.csv") do set VENTAS_HOY=%%~nxF
for %%F in ("%EXPORT_DIR%\ventas_prod_ult7d*.csv") do set VENTAS_PROD=%%~nxF

copy "%EXPORT_DIR%\%VENTAS_HOY%" "%DATA_DIR%" >nul
copy "%EXPORT_DIR%\%VENTAS_PROD%" "%DATA_DIR%" >nul

echo {> "%DATA_DIR%\latest.json"
echo   "ventas_hoy":"%VENTAS_HOY%",>> "%DATA_DIR%\latest.json"
echo   "ventas_prod_ult7d":"%VENTAS_PROD%" >> "%DATA_DIR%\latest.json"
echo }>> "%DATA_DIR%\latest.json"

cd "%~dp0..\web-app"
firebase deploy
:end
