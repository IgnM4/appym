-- stub_invalids.sql
SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
  -- === util: compone el tipo de dato legible a partir de USER_ARGUMENTS ===
  FUNCTION arg_type(
    p_data_type      VARCHAR2,
    p_len            NUMBER,
    p_prec           NUMBER,
    p_scale          NUMBER,
    p_type_owner     VARCHAR2,
    p_type_name      VARCHAR2
  ) RETURN VARCHAR2 IS
    v VARCHAR2(400);
  BEGIN
    IF p_data_type IN ('VARCHAR2','NVARCHAR2','CHAR','NCHAR') THEN
      IF p_len IS NOT NULL THEN
        v := p_data_type||'('||p_len||')';
      ELSE
        v := p_data_type;
      END IF;
    ELSIF p_data_type = 'NUMBER' THEN
      IF p_prec IS NOT NULL THEN
        IF p_scale IS NOT NULL THEN
          v := 'NUMBER('||p_prec||','||p_scale||')';
        ELSE
          v := 'NUMBER('||p_prec||')';
        END IF;
      ELSE
        v := 'NUMBER';
      END IF;
    ELSIF p_data_type IN ('DATE','CLOB','NCLOB','BLOB','BINARY_FLOAT','BINARY_DOUBLE') THEN
      v := p_data_type;
    ELSIF p_data_type LIKE 'TIMESTAMP%' THEN
      v := p_data_type;
    ELSIF p_type_name IS NOT NULL THEN
      v := COALESCE(p_type_owner||'.','')||p_type_name; -- tipos objeto
    ELSE
      v := p_data_type; -- fallback
    END IF;
    RETURN v;
  END;

  -- === util: genera lista de parámetros "(p1 IN NUMBER, p2 OUT VARCHAR2, ...)" ===
  FUNCTION param_list(p_obj VARCHAR2, p_type VARCHAR2) RETURN CLOB IS
    v CLOB := '';
    first BOOLEAN := TRUE;
  BEGIN
    FOR a IN (
      SELECT argument_name,
             in_out,
             data_type,
             data_length,
             data_precision,
             data_scale,
             type_owner,
             type_name
      FROM   user_arguments
      WHERE  object_name = p_obj
      AND    ( (p_type IN ('FUNCTION','PROCEDURE') AND data_level = 0 AND argument_name IS NOT NULL)
            OR (p_type = 'PACKAGE' AND 1=0) ) -- no usamos para package spec
      ORDER  BY position
    )
    LOOP
      IF NOT first THEN v := v || ', '; END IF;
      first := FALSE;
      v := v ||
           a.argument_name || ' ' ||
           REPLACE(NVL(a.in_out,'IN'),'IN/OUT','IN OUT') || ' ' ||
           arg_type(a.data_type, a.data_length, a.data_precision, a.data_scale, a.type_owner, a.type_name);
    END LOOP;
    RETURN v;
  END;

  -- === util: tipo retorno de función ===
  FUNCTION return_type(p_obj VARCHAR2) RETURN VARCHAR2 IS
    r user_arguments%ROWTYPE;
  BEGIN
    SELECT * INTO r
    FROM user_arguments
    WHERE object_name = p_obj
      AND argument_name IS NULL
      AND data_level = 0
      AND position = 0;
    RETURN arg_type(r.data_type, r.data_length, r.data_precision, r.data_scale, r.type_owner, r.type_name);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'VARCHAR2'; -- fallback seguro
  END;

  PROCEDURE make_function(p_name VARCHAR2) IS
    sig CLOB;
    ret VARCHAR2(400);
    ddl CLOB;
  BEGIN
    sig := param_list(p_name, 'FUNCTION');
    ret := return_type(p_name);
    ddl := 'CREATE OR REPLACE FUNCTION '||p_name||'('||sig||') RETURN '||ret||CHR(10)||
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
    sig CLOB;
    ddl CLOB;
  BEGIN
    sig := param_list(p_name, 'PROCEDURE');
    ddl := 'CREATE OR REPLACE PROCEDURE '||p_name||'('||sig||')'||CHR(10)||
           'IS'||CHR(10)||
           'BEGIN'||CHR(10)||
           '  NULL;'||CHR(10)||
           'END '||p_name||';';
    EXECUTE IMMEDIATE ddl;
    DBMS_OUTPUT.PUT_LINE('OK   PROCEDURE    '||p_name||' (stub)');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL PROCEDURE    '||p_name||' -> '||SQLERRM);
  END;

  PROCEDURE make_package_stub(p_name VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE PACKAGE '||p_name||' IS END '||p_name||';';
    DBMS_OUTPUT.PUT_LINE('OK   PACKAGE      '||p_name||' (spec vacía)');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL PACKAGE      '||p_name||' -> '||SQLERRM);
  END;

  PROCEDURE make_trigger_stub(p_name VARCHAR2) IS
    tname VARCHAR2(128);
    ddl   CLOB;
  BEGIN
    SELECT table_name INTO tname FROM user_triggers WHERE trigger_name = p_name;
    ddl := 'CREATE OR REPLACE TRIGGER '||p_name||CHR(10)||
           'BEFORE INSERT OR UPDATE OR DELETE ON '||tname||CHR(10)||
           'FOR EACH ROW'||CHR(10)||
           'BEGIN'||CHR(10)||
           '  NULL;'||CHR(10)||
           'END;';
    EXECUTE IMMEDIATE ddl;
    DBMS_OUTPUT.PUT_LINE('OK   TRIGGER      '||p_name||' (stub simple sobre '||tname||')');
  EXCEPTION WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('FAIL TRIGGER      '||p_name||' -> no existe en USER_TRIGGERS');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL TRIGGER      '||p_name||' -> '||SQLERRM);
  END;

BEGIN
  -- crea stubs SOLO si hoy están inválidos (no toca objetos válidos)
  FOR x IN (
    SELECT object_name, object_type
    FROM   user_objects
    WHERE  status = 'INVALID'
    AND    object_name IN ('CSV_STR','FN_GET_IVA','FN_RUT_ONLY_DIGITS','PKG_APP_CTX','PR_EXPORT_CLIENTES_GEO','TRG_BOLETA_SET_NUMERO')
  ) LOOP
    IF x.object_type = 'FUNCTION' THEN
      make_function(x.object_name);
    ELSIF x.object_type = 'PROCEDURE' THEN
      make_procedure(x.object_name);
    ELSIF x.object_type = 'PACKAGE' THEN
      make_package_stub(x.object_name);
    ELSIF x.object_type = 'TRIGGER' THEN
      make_trigger_stub(x.object_name);
    END IF;
  END LOOP;

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
