-- Procedure que refresca MVs y exporta CSVs con fecha
CREATE OR REPLACE PROCEDURE pr_export_kpis_daily AS
  v_stamp VARCHAR2(8) := TO_CHAR(SYSDATE,'YYYYMMDD');
BEGIN
  -- refresco
  pr_refresh_kpi_mv;

  -- export del día
  pr_export_ventas_diarias(
    TRUNC(SYSDATE), TRUNC(SYSDATE),
    'ventas_hoy_'||v_stamp||'.csv'
  );

  -- export últimos 7 días por producto
  pr_export_ventas_por_producto(
    TRUNC(SYSDATE)-6, TRUNC(SYSDATE),
    'ventas_prod_ult7d_'||v_stamp||'.csv'
  );
END;
/

-- (re)crear job diario
BEGIN
  DBMS_SCHEDULER.DROP_JOB('JOB_EXPORT_KPI_DAILY', TRUE);
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'JOB_EXPORT_KPI_DAILY',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'PR_EXPORT_KPIS_DAILY',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;BYHOUR=2;BYMINUTE=35;BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Exporta KPI CSV diariamente tras el refresh de MVs'
  );
END;
/
