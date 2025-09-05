CREATE OR REPLACE PROCEDURE pr_registrar_compra(p_id_compra IN NUMBER) IS
  v_dest NUMBER;
BEGIN
  SELECT id_ubicacion_destino INTO v_dest
    FROM compra
   WHERE id_compra = p_id_compra;

  FOR r IN (
    SELECT id_producto, cantidad
      FROM compra_det
     WHERE id_compra = p_id_compra
  ) LOOP
    MERGE INTO stock_ubicacion su
    USING dual
      ON (su.id_ubicacion = v_dest AND su.id_producto = r.id_producto)
    WHEN MATCHED THEN
      UPDATE SET su.llenos = su.llenos + r.cantidad,
                 su.fecha_actualizacion = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
      INSERT (id_ubicacion, id_producto, llenos, vacios, fecha_actualizacion)
      VALUES (v_dest, r.id_producto, r.cantidad, 0, SYSTIMESTAMP);

    INSERT INTO movimiento_stock
      (fecha, tipo, id_ubicacion_hasta, id_producto, cantidad, es_lleno, ref_tipo, ref_id)
    VALUES
      (SYSTIMESTAMP, 'COMPRA', v_dest, r.id_producto, r.cantidad, 'S', 'COMPRA', p_id_compra);
  END LOOP;
END;
