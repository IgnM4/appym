SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT ==> Refrescando MVs de KPIs...
BEGIN
  DBMS_MVIEW.REFRESH('MV_VENTAS_DIARIAS',      'C');
  DBMS_MVIEW.REFRESH('MV_VENTAS_POR_PRODUCTO', 'C');
END;
/

PROMPT ==> Disparando JOB_REFRESH_KPI_MV en background...
BEGIN
  DBMS_SCHEDULER.RUN_JOB('JOB_REFRESH_KPI_MV', use_current_session => FALSE);
END;
/

PROMPT ==> Estado de MVs:
SELECT mview_name, staleness,
       TO_CHAR(last_refresh_date,'YYYY-MM-DD HH24:MI') last_refresh
FROM   user_mviews
WHERE  mview_name IN ('MV_VENTAS_DIARIAS','MV_VENTAS_POR_PRODUCTO');

PROMPT ==> Estado del job:
SELECT job_name, state,
       TO_CHAR(last_start_date,'YYYY-MM-DD HH24:MI') last_start,
       TO_CHAR(next_run_date,'YYYY-MM-DD HH24:MI')  next_run
FROM   user_scheduler_jobs
WHERE  job_name='JOB_REFRESH_KPI_MV';

EXIT
