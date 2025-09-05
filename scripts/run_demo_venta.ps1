$sql = Join-Path $PSScriptRoot 'demo_venta.sql'

# Environment variables with defaults:
#   DB_USER            - database user (default APP_PYME)
#   DB_PASSWORD        - password (default change_me)
#   DB_CONNECT_STRING  - connection string (default //localhost:1521/XEPDB1)

$user = $env:DB_USER; if (-not $user) { $user = 'APP_PYME' }
$pass = $env:DB_PASSWORD; if (-not $pass) { $pass = 'change_me' }
$conn = $env:DB_CONNECT_STRING; if (-not $conn) { $conn = '//localhost:1521/XEPDB1' }

& sqlplus "$user/$pass@$conn" "@$sql"

