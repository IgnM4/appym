$SQL = @"
set heading off feedback off
select table_name from user_tables where table_name='CLIENTES';
exit
"@
$SQL | docker exec -i app-oracle-xe-1 bash -lc "sqlplus -s APP_PYME/app_pyme_pass@localhost:1521/XEPDB1"