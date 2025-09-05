SET PAGESIZE 200 LINESIZE 200
COLUMN mview_name FORMAT A30
COLUMN staleness FORMAT A20
COLUMN last_refresh_type FORMAT A12
COLUMN last_refresh_date FORMAT A19
COLUMN job_name FORMAT A20
COLUMN state FORMAT A14

PROMPT === MVs (estado) ===
SELECT mview_name,
       staleness,
       last_refresh_type,
       TO_CHAR(last_refresh_date,'YYYY-MM-DD HH24:MI') last_refresh_date
FROM user_mviews
ORDER BY mview_name;

PROMPT === Datos: mv_ventas_diarias (5) ===
SELECT * FROM mv_ventas_diarias
ORDER BY dia DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT === Datos: mv_ventas_por_producto (10) ===
SELECT sku, nombre, unidades_vendidas, monto_vendido
FROM mv_ventas_por_producto
ORDER BY sku
FETCH FIRST 10 ROWS ONLY;

PROMPT === Scheduler jobs ===
SELECT job_name, enabled, state
FROM user_scheduler_jobs
WHERE job_name IN ('JOB_REFRESH_KPI_MV','JOB_EXPORT_KPI_DAILY')
ORDER BY job_name;
