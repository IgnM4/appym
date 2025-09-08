-- stub_invalids_fix2.sql
SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
  -- Construye la lista de parámetros. Devuelve TRUE si hay alguno.
  FUNCTION build_params(p_obj VARCHAR2, p_sig OUT CLOB) RETURN BOOLEAN IS
    n INTEGER := 0;
  BEGIN
    p_sig := '';
    FOR a IN (
      SELECT argument_name,
             REPLACE(NVL(in_out,'IN'),'IN/OUT','IN OUT') AS in_out,
             data_type, data_length, data_precision, data_scale,
             type_owner, type_name
      FROM   user_arguments
      WHERE  object_name = p_obj
      AND    data_level = 0
      AND    argument_name IS NOT NULL
      ORDER  BY position
    ) LOOP
      IF n > 0 THEN p_sig := p_sig || ', '; END IF;
      n := n + 1;

      -- Arma el tipo
      DECLARE
        v_type VARCHAR2(400);
      BEGIN
        IF a.data_type IN ('VARCHAR2','NVARCHAR2','CHAR','NCHAR') THEN
          v_type := a.data_type || CASE WHEN a.data_length IS NOT NULL THEN '('||a.data_length||')' END;
        ELSIF a.data_type = 'NUMBER' THEN
          v_type := CASE
                      WHEN a.data_precision IS NOT NULL AND a.data_scale IS NOT NULL THEN 'NUMBER('||a.data_precision||','||a.data_scale||')'
                      WHEN a.data_precision IS NOT NULL THEN 'NUMBER('||a.data_precision||')'
                      ELSE 'NUMBER'
                    END;
        ELSIF a.data_type IN ('DATE','CLOB','NCLOB','BLOB','BINARY_FLOAT','BINARY_DOUBLE') THEN
          v_type := a.data_type;
        ELSIF a.data_type LIKE 'TIMESTAMP%' THEN
          v_type := a.data_type;
        ELSIF a.type_name IS NOT NULL THEN
          v_type := COALESCE(a.type_owner||'.','')||a.type_name;
        ELSE
          v_type := a.data_type;
        END IF;

        p_sig := p_sig || a.argument_name || ' ' || a.in_out || ' ' || v_type;
      END;
    END LOOP;
    RETURN n > 0;
  END;

  -- Tipo de retorno de una función (fallback VARCHAR2)
  FUNCTION ret_type(p_obj VARCHAR2) RETURN VARCHAR2 IS
    r user_arguments%ROWTYPE;
  BEGIN
    SELECT * INTO r
    FROM user_arguments
    WHERE object_name = p_obj
      AND argument_name IS NULL
      AND data_level = 0
      AND position = 0;
    RETURN CASE
      WHEN r.data_type = 'NUMBER' THEN
        CASE
          WHEN r.data_precision IS NOT NULL AND r.data_scale IS NOT NULL THEN 'NUMBER('||r.data_precision||','||r.data_scale||')'
          WHEN r.data_precision IS NOT NULL THEN 'NUMBER('||r.data_precision||')'
          ELSE 'NUMBER'
        END
      WHEN r.data_type IN ('VARCHAR2','NVARCHAR2','CHAR','NCHAR') THEN r.data_type||CASE WHEN r.data_length IS NOT NULL THEN '('||r.data_length||')' END
      WHEN r.data_type LIKE 'TIMESTAMP%' THEN r.data_type
      WHEN r.data_type IN ('DATE','CLOB','NCLOB','BLOB','BINARY_FLOAT','BINARY_DOUBLE') THEN r.data_type
      WHEN r.type_name IS NOT NULL THEN COALESCE(r.type_owner||'.','')||r.type_name
      ELSE r.data_type
    END;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'VARCHAR2';
  END;

  PROCEDURE make_function(p_name VARCHAR2) IS
    sig CLOB; hasargs BOOLEAN; rt VARCHAR2(400); ddl CLOB;
  BEGIN
    hasargs := build_params(p_name, sig);
    rt := ret_type(p_name);
    ddl := 'CREATE OR REPLACE FUNCTION '||p_name||
           CASE WHEN hasargs THEN '('||sig||')' ELSE '' END||
           ' RETURN '||rt||CHR(10)||
           'IS'||CHR(10)||
           'BEGIN'||CHR(10)||
           '  RETURN NULL;'||CHR(10)||
           'END '||p_name||';';
    EXECUTE IMMEDIATE ddl;
    DBMS_OUTPUT.PUT_LINE('OK   FUNCTION     '||p_name||' (stub)');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL FUNCTION     '||p_name||' -> '||SQLERRM);
  END;

  PROCEDURE make_procedure(p_name VARCHAR2) IS
    sig CLOB; hasargs BOOLEAN; ddl CLOB;
  BEGIN
    hasargs := build_params(p_name, sig);
    ddl := 'CREATE OR REPLACE PROCEDURE '||p_name||
           CASE WHEN hasargs THEN '('||sig||')' ELSE '' END||
           CHR(10)||'IS'||CHR(10)||
           'BEGIN'||CHR(10)||
           '  NULL;'||CHR(10)||
           'END '||p_name||';';
    EXECUTE IMMEDIATE ddl;
    DBMS_OUTPUT.PUT_LINE('OK   PROCEDURE    '||p_name||' (stub)');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL PROCEDURE    '||p_name||' -> '||SQLERRM);
  END;

BEGIN
  -- Crea/actualiza stubs SOLO si hoy están inválidos
  FOR x IN (
    SELECT object_name, object_type
    FROM   user_objects
    WHERE  status = 'INVALID'
    AND    object_name IN ('CSV_STR','FN_GET_IVA','FN_RUT_ONLY_DIGITS','PR_EXPORT_CLIENTES_GEO')
  ) LOOP
    IF x.object_type = 'FUNCTION' THEN
      make_function(x.object_name);
    ELSIF x.object_type = 'PROCEDURE' THEN
      make_procedure(x.object_name);
    END IF;
  END LOOP;

  -- Asegura un body vacío para PKG_APP_CTX si existiera la spec
  BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE PACKAGE BODY PKG_APP_CTX IS END PKG_APP_CTX;';
    DBMS_OUTPUT.PUT_LINE('OK   PACKAGE BODY PKG_APP_CTX (stub)');
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  DBMS_UTILITY.COMPILE_SCHEMA(USER, FALSE);
END;
/

-- Reporte
COLUMN NAME FORMAT A30
SELECT name, type, line, position, text
FROM   user_errors
ORDER  BY name, sequence;

SELECT object_type, object_name
FROM   user_objects
WHERE  status='INVALID'
ORDER  BY 1,2;
