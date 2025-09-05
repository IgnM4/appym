-- scripts/check_scheduler.sql
COLUMN last_start FORMAT A19
COLUMN next_run   FORMAT A19
SELECT job_name, enabled, state, logging_level,
       TO_CHAR(last_start_date,'YYYY-MM-DD HH24:MI:SS') last_start,
       TO_CHAR(next_run_date,'YYYY-MM-DD HH24:MI:SS')   next_run
FROM   user_scheduler_jobs
WHERE  job_name IN ('JOB_REFRESH_KPI_MV','JOB_EXPORT_KPI_DAILY')
ORDER  BY job_name;

PROMPT === Últimas corridas (detalle) ===
COLUMN started  FORMAT A19
COLUMN duration FORMAT A12
SELECT log_id, job_name, status,
       TO_CHAR(actual_start_date,'YYYY-MM-DD HH24:MI:SS') started,
       TO_CHAR(run_duration,'HH24:MI:SS') duration,
       error#, additional_info
FROM   user_scheduler_job_run_details
WHERE  job_name IN ('JOB_REFRESH_KPI_MV','JOB_EXPORT_KPI_DAILY')
ORDER  BY log_id DESC FETCH FIRST 10 ROWS ONLY;

PROMPT === Bitácora general ===
COLUMN log_date FORMAT A19
SELECT log_id, job_name, operation, status,
       TO_CHAR(log_date,'YYYY-MM-DD HH24:MI:SS') log_date
FROM   user_scheduler_job_log
WHERE  job_name IN ('JOB_REFRESH_KPI_MV','JOB_EXPORT_KPI_DAILY')
ORDER  BY log_id DESC FETCH FIRST 10 ROWS ONLY;
