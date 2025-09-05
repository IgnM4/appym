SET SERVEROUTPUT ON;
PROMPT == Materialized Views ==
SELECT mview_name, last_refresh_date, staleness
FROM user_mviews
WHERE mview_name LIKE 'MV_%';

PROMPT == Ventas hoy ==
SELECT * FROM v_kpi_ventas_diarias FETCH FIRST 5 ROWS ONLY;

PROMPT == Ventas por producto 7d ==
SELECT * FROM v_kpi_ventas_por_producto FETCH FIRST 5 ROWS ONLY;

PROMPT == Scheduler jobs ==
SELECT job_name, state, last_start_date, next_run_date
FROM user_scheduler_jobs
WHERE job_name LIKE 'PR_%' OR job_name LIKE 'EXPORT%';
