-- Quita terminadores/atributos superfluos por si usamos GET_DDL (solo views)
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SEGMENT_ATTRIBUTES',FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',FALSE);
END;
/
SET DEFINE OFF
SET SERVEROUTPUT ON

-- Borra objetos basura si existen (no falla si no están)
BEGIN
  BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION "FUNCTION"'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF; END;
  BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE "PACKAGE"'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF; END;
  BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE BODY "PACKAGE"'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF; END;
END;
/

DECLARE
  -- Devuelve fuente limpia desde USER_SOURCE:
  -- * sin líneas "/" puras
  -- * sin 'ALTER TRIGGER ...'
  -- * recortada hasta el ÚLTIMO 'END [name];' (para cortar cualquier CREATE posterior)
  FUNCTION get_clean_src(p_name VARCHAR2, p_type VARCHAR2) RETURN CLOB IS
    c   CLOB;
    nm  VARCHAR2(128) := p_name;
  BEGIN
    -- Une líneas del objeto
    SELECT XMLCAST(
             XMLAGG(
               XMLELEMENT(e,
                 CASE
                   WHEN REGEXP_LIKE(text,'^\s*/\s*$','n') THEN NULL
                   ELSE text || CHR(10)
                 END
               ) ORDER BY line
             ) AS CLOB
           )
      INTO c
      FROM user_source
     WHERE name = p_name
       AND type = p_type;

    IF c IS NULL THEN
      RETURN NULL;
    END IF;

    -- Para triggers: elimina cualquier ALTER TRIGGER ... (en cualquier parte)
    IF p_type = 'TRIGGER' THEN
      c := REGEXP_REPLACE(c, '(^|\n)\s*ALTER\s+TRIGGER\b.*$', '', 1, 0, 'imn');
    END IF;

    -- Corta TODO lo que aparezca después del ÚLTIMO END [name];
    -- Greedy hasta el último END opcionalmente seguido del nombre.
    c := REGEXP_REPLACE(
           c,
           '^(.*END(\s+'||nm||')?\s*;).*$',  -- conserva hasta el END final del propio objeto
           '\1',
           1, 0, 'inm'
         );

    RETURN c;
  END;

  PROCEDURE recreate(p_name VARCHAR2, p_type VARCHAR2) IS
    v_src  CLOB;
    v_stmt CLOB;
  BEGIN
    IF p_type = 'VIEW' THEN
      v_stmt := DBMS_METADATA.GET_DDL('VIEW', p_name, USER);
      EXECUTE IMMEDIATE v_stmt;
      DBMS_OUTPUT.PUT_LINE('OK   VIEW         '||p_name);
      RETURN;
    END IF;

    v_src := get_clean_src(p_name, p_type);

    IF v_src IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('SKIP '||RPAD(p_type,12)||' '||p_name||' (sin fuente en USER_SOURCE)');
      RETURN;
    END IF;

    -- Si ya empieza con CREATE, úsalo tal cual; si no, anteponer CREATE OR REPLACE
    IF REGEXP_LIKE(v_src, '^\s*CREATE(\s+OR\s+REPLACE)?\s+', 'in') THEN
      v_stmt := v_src;
    ELSE
      v_stmt := 'CREATE OR REPLACE '||v_src;
    END IF;

    -- Asegura ';' final (no '/')
    IF NOT REGEXP_LIKE(v_stmt, ';\s*\z', 'n') THEN
      v_stmt := v_stmt || ';';
    END IF;

    EXECUTE IMMEDIATE v_stmt;
    DBMS_OUTPUT.PUT_LINE('OK   '||RPAD(p_type,12)||' '||p_name);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('FAIL '||RPAD(p_type,12)||' '||p_name||' -> '||SQLERRM);
  END;
BEGIN
  -- Orden de dependencias: funciones base → package → body → dependientes → trigger
  recreate('CSV_STR',            'FUNCTION');
  recreate('FN_GET_IVA',         'FUNCTION');
  recreate('FN_RUT_ONLY_DIGITS', 'FUNCTION');

  recreate('PKG_APP_CTX',        'PACKAGE');
  recreate('PKG_APP_CTX',        'PACKAGE BODY');

  recreate('PR_EXPORT_CLIENTES_GEO', 'PROCEDURE');
  recreate('TRG_BOLETA_SET_NUMERO',  'TRIGGER');

  DBMS_UTILITY.COMPILE_SCHEMA(USER, FALSE);
END;
/
-- Errores detallados (si quedan)
COLUMN NAME FORMAT A30
SELECT name, type, line, position, text
FROM   user_errors
ORDER  BY name, sequence;

-- Lista de inválidos final
SELECT object_type, object_name
FROM   user_objects
WHERE  status='INVALID'
ORDER  BY 1,2;
