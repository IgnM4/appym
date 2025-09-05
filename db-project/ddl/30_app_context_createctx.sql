DECLARE
  -- ya existe (dos variantes posibles según versión)
  e_ctx_exists_29443 EXCEPTION; PRAGMA EXCEPTION_INIT(e_ctx_exists_29443, -29443);
  e_ctx_exists_955   EXCEPTION; PRAGMA EXCEPTION_INIT(e_ctx_exists_955,   -955);
  -- falta privilegio (si lo crea SYS)
  e_no_priv          EXCEPTION; PRAGMA EXCEPTION_INIT(e_no_priv,          -1031);
BEGIN
  EXECUTE IMMEDIATE 'CREATE CONTEXT app_pyme_ctx USING pkg_app_ctx';
EXCEPTION
  WHEN e_ctx_exists_29443 THEN NULL; -- ya existe
  WHEN e_ctx_exists_955   THEN NULL; -- ya existe
  WHEN e_no_priv          THEN NULL; -- sin privilegio aquí (lo creó SYS)
END;
/
