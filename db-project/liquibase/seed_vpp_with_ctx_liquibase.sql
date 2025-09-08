-- Liquibase-friendly seed: sin SET/PROMPT/SQL*Plus
-- 1) Setear contexto
DECLARE
BEGIN
  PKG_APP_CTX.SET_ID_USUARIO(1);
END;
/

-- 2) Asegurar productos base
DECLARE
  PROCEDURE ensure_prod(p_sku VARCHAR2, p_nombre VARCHAR2, p_formato VARCHAR2, p_um VARCHAR2, p_costo NUMBER, p_precio NUMBER) IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt FROM producto WHERE sku = p_sku;
    IF v_cnt = 0 THEN
      INSERT INTO producto (sku, nombre, formato, unidad_medida, costo, precio, activo, fecha_creacion, creado_por)
      VALUES (p_sku, p_nombre, p_formato, p_um, p_costo, p_precio, 'S', SYSTIMESTAMP, USER);
    END IF;
  END;
BEGIN
  ensure_prod('SKU-11KG','Gas 11 kg','11KG','UN',8000,12000);
  ensure_prod('SKU-5KG','Gas 5 kg','5KG','UN',4000, 6000);
END;
/

-- 3) Insertar boleta y detalle
DECLARE
  v_boleta  NUMBER;
  v_p1      NUMBER;
  v_p2      NUMBER;
  v_numero  NUMBER;
BEGIN
  SELECT SEQ_BOLETA_NUMERO.NEXTVAL INTO v_numero FROM dual;

  INSERT INTO boleta_venta (numero, fecha, id_cliente, neto, iva, total, metodo_pago, estado)
  VALUES (v_numero, SYSDATE, NULL, 18000, 3420, 21420, 'EFECTIVO', 'PAGADA')
  RETURNING id_boleta INTO v_boleta;

  SELECT id_producto INTO v_p1 FROM producto WHERE sku = 'SKU-11KG';
  SELECT id_producto INTO v_p2 FROM producto WHERE sku = 'SKU-5KG';

  INSERT INTO boleta_venta_detalle (id_boleta, id_producto, cantidad, precio_unitario, descuento)
  VALUES (v_boleta, v_p1, 1, 12000, 0);

  INSERT INTO boleta_venta_detalle (id_boleta, id_producto, cantidad, precio_unitario, descuento)
  VALUES (v_boleta, v_p2, 1,  6000, 0);
END;
/

-- 4) Refrescar la MV
BEGIN
  DBMS_MVIEW.REFRESH('MV_VENTAS_POR_PRODUCTO','C');
END;
/
