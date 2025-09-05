# restart-all.ps1
$ErrorActionPreference = "Stop"

cd $PSScriptRoot

# 1) Libera puertos Oracle en Windows (por si el listener local se levanta)
Get-Process -Name tnslsnr -ErrorAction SilentlyContinue | Stop-Process -Force
(Get-NetTCPConnection -LocalPort 1521,5500 -State Listen -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique) | ForEach-Object { try { Stop-Process -Id $_ -Force } catch {} }

# 2) Sube Oracle
docker compose up -d
Write-Host "Esperando Oracle..." -ForegroundColor Yellow
for ($i=0; $i -lt 60; $i++) {
  $status = (docker inspect -f "{{.State.Health.Status}}" app-oracle-xe-1 2>$null)
  if ($status -eq "healthy") { Write-Host "Oracle healthy ✅"; break }
  Start-Sleep -Seconds 5
}

# 3) Exporta variables para la sesión actual (por si no hay .env loader)
$env:PORT="4000"
$env:DB_USER="APP_PYME"
$env:DB_PASSWORD="app_pyme_pass"
$env:DB_CONNECT="localhost:1521/XEPDB1"

# 4) Arranca la API (en una nueva ventana)
$apiPath = Join-Path $PSScriptRoot "apps\api"
if (Test-Path (Join-Path $apiPath "package.json")) {
  Start-Process powershell -ArgumentList '-NoExit','-Command',"cd '$apiPath'; npm run dev"
  Start-Sleep -Seconds 2
  try { Invoke-RestMethod http://localhost:4000/health | Out-Host } catch { Write-Host "La API aún inicia..." }
} else {
  Write-Warning "No encuentro apps\api\package.json"
}
