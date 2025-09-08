-- Crea el contexto APP_PYME_CTX apuntando al paquete de APP_PYME (idempotente)
BEGIN
  EXECUTE IMMEDIATE 'CREATE CONTEXT APP_PYME_CTX USING APP_PYME.PKG_APP_CTX';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -955 THEN RAISE; END IF; -- ORA-00955: ya existe
END;
/

-- Verificación (opcional; como SYS)
SET LINES 200
COLUMN namespace FORMAT A20
COLUMN schema FORMAT A20
COLUMN package FORMAT A30
SELECT namespace, schema, package
FROM   dba_context
WHERE  namespace IN ('APP_CTX','APP_PYME_CTX');
/
