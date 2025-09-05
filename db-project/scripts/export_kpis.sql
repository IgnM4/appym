ALTER SESSION SET query_rewrite_enabled = TRUE;

BEGIN pr_refresh_kpi_mv; END;
/

BEGIN
  pr_export_ventas_diarias(TRUNC(SYSDATE), TRUNC(SYSDATE), 'ventas_hoy.csv');
END;
/

BEGIN
  pr_export_ventas_por_producto(TRUNC(SYSDATE)-6, TRUNC(SYSDATE), 'ventas_prod_ult7d.csv');
END;
/

PROMPT === Archivos esperados en C:\oracle_export ===
HOST dir C:\oracle_export\ventas_*.csv
