-- Crea (o recrea) el contexto APP_CTX y lo asocia al package de APP_PYME
BEGIN
  EXECUTE IMMEDIATE 'DROP CONTEXT APP_CTX';
EXCEPTION
  WHEN OTHERS THEN NULL; -- si no existe, seguimos
END;
/
CREATE CONTEXT APP_CTX USING APP_PYME.PKG_APP_CTX;
/

-- Verificación (como SYS)
COL NAMESPACE FORMAT A15
COL SCHEMA    FORMAT A15
COL PACKAGE   FORMAT A25
SELECT namespace, schema, package
FROM   dba_context
WHERE  namespace = 'APP_CTX';
/
