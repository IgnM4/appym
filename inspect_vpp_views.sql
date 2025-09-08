SET PAGESIZE 200 LINESIZE 200 LONG 100000
COLUMN object_name FORMAT A30
COLUMN view_name   FORMAT A30
COLUMN text        FORMAT A120 WORD_WRAPPED

PROMPT == ¿Existe BOLETA_VENTA_DETALLE y qué tipo es? ==
SELECT object_name, object_type
FROM user_objects
WHERE object_name IN ('BOLETA_VENTA_DETALLE','BOLETA_ITEM','VENTA_ITEM','PRODUCTO','BOLETA_VENTA')
ORDER BY 1;

PROMPT == DDL de la vista (si es vista) ==
DECLARE v_ddl CLOB;
BEGIN
  BEGIN
    v_ddl := DBMS_METADATA.GET_DDL('VIEW','BOLETA_VENTA_DETALLE',USER);
    DBMS_OUTPUT.PUT_LINE(v_ddl);
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('No es VIEW o no existe como VIEW.');
  END;
END;
/

PROMPT == Columnas que debería tener para la MV ==
SELECT table_name, column_name, data_type
FROM user_tab_columns
WHERE table_name IN ('BOLETA_VENTA_DETALLE','BOLETA_ITEM','PRODUCTO','BOLETA_VENTA')
ORDER BY table_name, column_id;
