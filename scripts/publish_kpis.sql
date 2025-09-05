ALTER SESSION SET query_rewrite_enabled=TRUE;
BEGIN
  pr_refresh_kpi_mv;
  pr_export_kpis_daily;
END;
/
