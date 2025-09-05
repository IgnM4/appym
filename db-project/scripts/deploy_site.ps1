param(
  [string]$ExportDir = "C:\oracle_export",
  [string]$WebDir = "$PSScriptRoot\..\web"  # ajusta si cambias estructura
)

$dst = Join-Path $WebDir "public\data"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

Copy-Item -Force (Join-Path $ExportDir "ventas_hoy.csv") $dst
Copy-Item -Force (Join-Path $ExportDir "ventas_prod_ult7d.csv") $dst

Push-Location $WebDir
firebase deploy --only hosting
Pop-Location
