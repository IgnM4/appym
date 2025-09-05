-- Uso:
-- VAR sku VARCHAR2(20); EXEC :sku := 'GAS-11';
-- VAR qty NUMBER;        EXEC :qty := 2;
-- @scripts/insert_venta_por_sku.sql

DECLARE
  v_prod_id   NUMBER;
  v_precio    NUMBER;
  v_boleta_id NUMBER;
  v_det_id    NUMBER;
  v_rate      CONSTANT NUMBER := 0.19;
  v_total     NUMBER; v_neto NUMBER; v_iva NUMBER;
BEGIN
  SELECT id_producto, precio INTO v_prod_id, v_precio FROM producto WHERE sku = :sku;

  v_total := v_precio * :qty;
  v_neto  := ROUND(v_total / (1+v_rate));
  v_iva   := v_total - v_neto;

  INSERT INTO boleta_venta (fecha, estado, neto, iva, total, id_usuario_vende)
  VALUES (SYSTIMESTAMP, 'PAGADA', v_neto, v_iva, v_total, 1)
  RETURNING id_boleta INTO v_boleta_id;

  SELECT NVL(MAX(id_detalle),0)+1 INTO v_det_id FROM boleta_venta_detalle;

  INSERT INTO boleta_venta_detalle (id_detalle, id_boleta, id_producto, cantidad, precio_unitario, descuento)
  VALUES (v_det_id, v_boleta_id, v_prod_id, :qty, v_precio, 0);

  COMMIT;
END;
/
BEGIN
  DBMS_MVIEW.REFRESH(list => 'MV_VENTAS_DIARIAS',      method => 'C', atomic_refresh => FALSE);
  DBMS_MVIEW.REFRESH(list => 'MV_VENTAS_POR_PRODUCTO', method => 'C', atomic_refresh => FALSE);
END;
/
