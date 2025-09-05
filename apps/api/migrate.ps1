param(
  [string]$Service   = "XEPDB1",
  [string]$User      = "APP_PYME",
  [string]$Pass      = "app_pyme_pass",
  [string]$Container = "app-oracle-xe-1"
)

$ErrorActionPreference = "Stop"

# Directorio de migraciones
$dir = Join-Path $PSScriptRoot "db\migrations"
$files = Get-ChildItem -Path $dir -Filter "*.sql" | Sort-Object Name

if (-not $files) {
  Write-Warning "No hay archivos .sql en $dir"
  exit 0
}

foreach ($f in $files) {
  $dest = "/tmp/mig-$($f.Name)"
  $containerDest = "{0}:{1}" -f $Container, $dest   # evita problema con ":" en PowerShell

  Write-Host ">> Aplicando $($f.Name)" -ForegroundColor Cyan

  # 1) Copia el archivo al contenedor
  docker cp "$($f.FullName)" "$containerDest" | Out-Null

  # 2) Ejecuta con sqlplus dentro del contenedor
  #    Ojo con comillas en la password
  $sqlplus = "sqlplus -s $User/`"$Pass`"@localhost:1521/$Service @$dest"
  $res = docker exec $Container bash -lc "$sqlplus"
  $exit = $LASTEXITCODE

  if ($exit -ne 0) {
    Write-Error "Falló $($f.Name) (exit $exit). Salida:`n$res"
    exit $exit
  } else {
    Write-Host $res
    Write-Host "OK $($f.Name) ✅" -ForegroundColor Green
  }

  # 3) Limpieza opcional del archivo temporal
docker exec $Container bash -lc "rm -f '$dest' || true" | Out-Null
}

Write-Host "Todas las migraciones aplicadas ✅" -ForegroundColor Green
