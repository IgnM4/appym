param(
  [string]$Url = "jdbc:oracle:thin:@//oracle-xe:1521/XEPDB1",
  [string]$User = "APP_PYME",
  [string]$Pass = "app_pyme",
  [string]$Schema = "APP_PYME"
)

docker run --rm --network liquinet `
  -v "${PWD}:/work" -w /work/liquibase `
  liquibase/liquibase:4.33.0 `
  --defaultsFile=/dev/null `
  --changelog-file=changelog-master.xml `
  --url="$Url" `
  --username=$User --password=$Pass `
  --defaultSchemaName=$Schema `
  --contexts="!admin,demo" update
