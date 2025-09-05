-- ===== Funciones utilitarias RUT CL =====
CREATE OR REPLACE FUNCTION fn_rut_only_digits(p_rut VARCHAR2)
RETURN VARCHAR2 DETERMINISTIC IS
  v VARCHAR2(64);
BEGIN
  -- quita puntos, guiones y espacios
  v := UPPER(REGEXP_REPLACE(p_rut, '[\.\- ]', ''));
  RETURN v;
END;
/

CREATE OR REPLACE FUNCTION fn_rut_calc_dv(p_num VARCHAR2)
RETURN VARCHAR2 DETERMINISTIC IS
  -- p_num: solo dígitos (parte izquierda)
  s NUMBER := 0;
  m NUMBER := 2;
  c CHAR(1);
BEGIN
  FOR i IN REVERSE 1..LENGTH(p_num) LOOP
    s := s + TO_NUMBER(SUBSTR(p_num, i, 1)) * m;
    m := CASE WHEN m = 7 THEN 2 ELSE m + 1 END;
  END LOOP;
  s := 11 - MOD(s, 11);
  IF s = 11 THEN c := '0';
  ELSIF s = 10 THEN c := 'K';
  ELSE c := TO_CHAR(s);
  END IF;
  RETURN c;
END;
/

CREATE OR REPLACE FUNCTION fn_rut_valida(p_rut VARCHAR2)
RETURN NUMBER DETERMINISTIC IS
  v VARCHAR2(64) := fn_rut_only_digits(p_rut);
  n VARCHAR2(64);
  dv CHAR(1);
  dv_calc CHAR(1);
BEGIN
  IF p_rut IS NULL THEN RETURN 1; END IF; -- NULL permitido (p.ej. consumidor final)
  IF NOT REGEXP_LIKE(v, '^[0-9]+[0-9K]$') THEN RETURN 0; END IF;
  n := SUBSTR(v, 1, LENGTH(v)-1);
  dv := SUBSTR(v, -1, 1);
  dv_calc := fn_rut_calc_dv(n);
  RETURN CASE WHEN dv_calc = dv THEN 1 ELSE 0 END;
END;
/

CREATE OR REPLACE FUNCTION fn_rut_normaliza(p_rut VARCHAR2)
RETURN VARCHAR2 DETERMINISTIC IS
  v VARCHAR2(64) := fn_rut_only_digits(p_rut);
  n VARCHAR2(64);
  dv CHAR(1);
BEGIN
  IF p_rut IS NULL THEN RETURN NULL; END IF;
  n  := SUBSTR(v, 1, LENGTH(v)-1);
  dv := SUBSTR(v, -1, 1);
  RETURN n || '-' || dv; -- sin puntos, con guión
END;
/

-- ===== Triggers de validación/normalización =====
CREATE OR REPLACE TRIGGER trg_proveedor_rut
BEFORE INSERT OR UPDATE OF rut ON proveedor
FOR EACH ROW
BEGIN
  IF :NEW.rut IS NOT NULL THEN
    IF fn_rut_valida(:NEW.rut) = 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'RUT de proveedor inválido');
    END IF;
    :NEW.rut := fn_rut_normaliza(:NEW.rut);
  END IF;
END;
/
SHOW ERRORS TRIGGER trg_proveedor_rut

CREATE OR REPLACE TRIGGER trg_cliente_rut
BEFORE INSERT OR UPDATE OF rut ON cliente
FOR EACH ROW
BEGIN
  -- RUT es opcional; si viene, debe ser válido
  IF :NEW.rut IS NOT NULL THEN
    IF fn_rut_valida(:NEW.rut) = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'RUT de cliente inválido');
    END IF;
    :NEW.rut := fn_rut_normaliza(:NEW.rut);
  END IF;
END;
/
SHOW ERRORS TRIGGER trg_cliente_rut
