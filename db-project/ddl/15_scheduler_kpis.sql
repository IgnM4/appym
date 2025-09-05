CREATE OR REPLACE PROCEDURE pr_refresh_kpi_mv AS
BEGIN
  DBMS_MVIEW.REFRESH('MV_VENTAS_DIARIAS', 'C');
  DBMS_MVIEW.REFRESH('MV_VENTAS_POR_PRODUCTO', 'C');
END;
/

BEGIN
  DBMS_SCHEDULER.DROP_JOB('JOB_REFRESH_KPI_MV', TRUE);
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'JOB_REFRESH_KPI_MV',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'PR_REFRESH_KPI_MV',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;BYHOUR=2;BYMINUTE=30;BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Refresco nocturno de MVs KPI'
  );
END;
/
