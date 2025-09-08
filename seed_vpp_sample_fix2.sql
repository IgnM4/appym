SET SERVEROUTPUT ON
WHENEVER SQLERROR CONTINUE

DECLARE
  v_sku      VARCHAR2(50) := 'SKU-001';
  v_id_prod  NUMBER;
  v_formato  VARCHAR2(100) := 'UNIDAD'; -- fallback
  v_unidad   VARCHAR2(20)  := 'UN';     -- fallback
  v_cnt      NUMBER;
BEGIN
  -- Leer 1er valor permitido del constraint CK_PRODUCTO__FORMATO (si existe)
  BEGIN
    SELECT REGEXP_SUBSTR(search_condition, '''([^'']*)''', 1, 1, NULL, 1)
      INTO v_formato
      FROM user_constraints
     WHERE table_name = 'PRODUCTO'
       AND constraint_name = 'CK_PRODUCTO__FORMATO';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
  END;

  -- Leer 1er valor permitido del constraint CK_PRODUCTO__UNIDAD_MEDIDA (si existe)
  BEGIN
    SELECT REGEXP_SUBSTR(search_condition, '''([^'']*)''', 1, 1, NULL, 1)
      INTO v_unidad
      FROM user_constraints
     WHERE table_name = 'PRODUCTO'
       AND constraint_name = 'CK_PRODUCTO__UNIDAD_MEDIDA';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
  END;

  DBMS_OUTPUT.PUT_LINE('Usando FORMATO='||v_formato||'  UNIDAD_MEDIDA='||v_unidad);

  -- Upsert de PRODUCTO con valores válidos según constraints
  MERGE INTO PRODUCTO p
  USING (SELECT v_sku AS sku FROM dual) s
  ON (p.SKU = s.sku)
  WHEN NOT MATCHED THEN
    INSERT (SKU, NOMBRE, FORMATO, UNIDAD_MEDIDA, COSTO, PRECIO, ACTIVO, CREADO_POR, FECHA_CREACION)
    VALUES (s.sku, 'Producto Demo', v_formato, v_unidad, 1000, 4995, 'S', USER, SYSTIMESTAMP)
  WHEN MATCHED THEN
    UPDATE SET
      p.NOMBRE        = 'Producto Demo',
      p.FORMATO       = v_formato,
      p.UNIDAD_MEDIDA = v_unidad,
      p.COSTO         = 1000,
      p.PRECIO        = 4995,
      p.ACTIVO        = 'S';

  SELECT ID_PRODUCTO INTO v_id_prod
  FROM PRODUCTO WHERE SKU = v_sku FETCH FIRST 1 ROWS ONLY;

  -- Boleta PAGADA base
  SELECT COUNT(*) INTO v_cnt FROM BOLETA_VENTA WHERE ID_BOLETA = 1001;
  IF v_cnt = 0 THEN
    INSERT INTO BOLETA_VENTA (
      ID_BOLETA, NUMERO, FECHA, ID_USUARIO_VENDE, ID_CLIENTE,
      NETO, IVA, TOTAL, METODO_PAGO, ESTADO,
      FECHA_CREACION, CREADO_POR, INVENTARIO_IMPACTADO
    ) VALUES (
      1001, '1001', SYSDATE, NULL, NULL,
      9990, 1900, 11890, 'EFECTIVO', 'PAGADA',
      SYSTIMESTAMP, USER, 'N'
    );
  END IF;

  -- Detalle: si ID_DETALLE es NOT NULL, calculamos MAX+1
  BEGIN
    INSERT INTO BOLETA_VENTA_DETALLE (ID_BOLETA, ID_PRODUCTO, CANTIDAD, PRECIO_UNITARIO, DESCUENTO, SUBTOTAL)
    VALUES (1001, v_id_prod, 2, 4995, 0, 9990);
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -1400 THEN
        DECLARE v_new_id NUMBER;
        BEGIN
          SELECT NVL(MAX(ID_DETALLE),0)+1 INTO v_new_id FROM BOLETA_VENTA_DETALLE;
          INSERT INTO BOLETA_VENTA_DETALLE
            (ID_DETALLE, ID_BOLETA, ID_PRODUCTO, CANTIDAD, PRECIO_UNITARIO, DESCUENTO, SUBTOTAL)
          VALUES
            (v_new_id, 1001, v_id_prod, 2, 4995, 0, 9990);
        END;
      ELSE
        RAISE;
      END IF;
  END;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('OK: datos de prueba listos.');
END;
/
PROMPT == Refresh MV ==
BEGIN DBMS_MVIEW.REFRESH('MV_VENTAS_POR_PRODUCTO','C'); END;
/
PROMPT == Filas en MV ==
SELECT COUNT(*) AS FILAS FROM MV_VENTAS_POR_PRODUCTO;
PROMPT == Top 5 ==
SELECT * FROM MV_VENTAS_POR_PRODUCTO FETCH FIRST 5 ROWS ONLY;

PROMPT == (Debug) Constraints PRODUCTO ==
SELECT constraint_name, search_condition
FROM user_constraints
WHERE table_name='PRODUCTO' AND constraint_type='C'
ORDER BY constraint_name;
