param()

$ErrorActionPreference = "Stop"

# 1) Asegura Docker Desktop
try {
  docker version | Out-Null
} catch {
  & "C:\Program Files\Docker\Docker\Docker Desktop.exe" | Out-Null
  Write-Host "Esperando Docker Desktop..."
  Start-Sleep -Seconds 10
}

# 2) Si existe el contenedor, arráncalo; si no, crea con compose
$exists = (docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq "app-oracle-xe-1" })
if ($exists) {
  Write-Host "Contenedor existente encontrado: app-oracle-xe-1"
  docker start app-oracle-xe-1 | Out-Null
} else {
  Write-Host "No existe contenedor. Creando con docker compose..."
  docker compose up -d
}

# 3) Chequeo rápido
docker ps --filter "name=app-oracle-xe-1"

# 4) (Opcional) lanzar API desde el monorepo
Write-Host "Lanzando API en nueva ventana..."
Start-Process powershell -ArgumentList '-NoExit','-Command',
  'cd "$PWD\apps\api"; npm run dev'
