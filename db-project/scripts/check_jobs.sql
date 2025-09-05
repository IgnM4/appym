-- SET PAGESIZE 200 LINESIZE 200
-- COLUMN job_name FORMAT A30
-- COLUMN state FORMAT A12
-- COLUMN last_start_date FORMAT A19
-- COLUMN next_run_date FORMAT A19

-- PROMPT === USER_SCHEDULER_JOBS ===
SELECT job_name,
       state,
       TO_CHAR(last_start_date,'YYYY-MM-DD HH24:MI') last_start_date,
       TO_CHAR(next_run_date,'YYYY-MM-DD HH24:MI') next_run_date
FROM user_scheduler_jobs
ORDER BY job_name;

-- PROMPT === USER_SCHEDULER_JOB_RUN_DETAILS (últimos 20) ===
SELECT * FROM (
  SELECT job_name,
         status,
         TO_CHAR(log_date,'YYYY-MM-DD HH24:MI') log_date,
         error#,
         additional_info
  FROM user_scheduler_job_run_details
  ORDER BY log_date DESC
) WHERE ROWNUM <= 20;

-- PROMPT === Materialized Views ===
-- COLUMN mview_name FORMAT A30
-- COLUMN staleness FORMAT A15
-- COLUMN last_refresh_date FORMAT A19
SELECT mview_name,
       staleness,
       TO_CHAR(last_refresh_date,'YYYY-MM-DD HH24:MI') last_refresh_date
FROM user_mviews
ORDER BY mview_name;
