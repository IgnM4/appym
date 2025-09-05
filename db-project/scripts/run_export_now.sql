-- scripts/run_export_now.sql
SET SERVEROUTPUT ON
BEGIN
  pr_export_kpis_daily;
  DBMS_OUTPUT.PUT_LINE('OK: pr_export_kpis_daily ejecutado.');
END;
/
HOST dir C:\oracle_export\ventas_hoy_*.csv
HOST dir C:\oracle_export\ventas_prod_ult7d_*.csv
