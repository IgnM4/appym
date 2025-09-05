-- Helper: obtiene IVA (default 0.19 si no existe)
CREATE OR REPLACE FUNCTION fn_get_iva RETURN NUMBER IS
  v NUMBER := 0.19;
BEGIN
  SELECT NVL(MAX(valor_num),0.19) INTO v
  FROM parametro_sistema WHERE codigo='IVA';
  RETURN v;
EXCEPTION WHEN OTHERS THEN
  RETURN 0.19;
END;
/

-- Recalcular totales de factura_compra
CREATE OR REPLACE PROCEDURE pr_recalc_fc(p_id IN NUMBER) IS
  v_neto NUMBER := 0; v_iva NUMBER := 0; v_total NUMBER := 0;
  v_iva_rate NUMBER := fn_get_iva;
BEGIN
  SELECT NVL(SUM(subtotal),0) INTO v_neto
  FROM factura_compra_detalle WHERE id_factura_compra = p_id;
  v_iva := ROUND(v_neto * v_iva_rate, 2);
  v_total := v_neto + v_iva;

  UPDATE factura_compra
  SET neto = v_neto, iva = v_iva, total = v_total
  WHERE id_factura_compra = p_id;
END;
/

-- Recalcular totales de boleta_venta
CREATE OR REPLACE PROCEDURE pr_recalc_bol(p_id IN NUMBER) IS
  v_neto NUMBER := 0; v_iva NUMBER := 0; v_total NUMBER := 0;
  v_iva_rate NUMBER := fn_get_iva;
BEGIN
  SELECT NVL(SUM(subtotal),0) INTO v_neto
  FROM boleta_venta_detalle WHERE id_boleta = p_id;
  v_iva := ROUND(v_neto * v_iva_rate, 2);
  v_total := v_neto + v_iva;

  UPDATE boleta_venta
  SET neto = v_neto, iva = v_iva, total = v_total
  WHERE id_boleta = p_id;
END;
/

-- Ajusta stock con upsert básico
CREATE OR REPLACE PROCEDURE pr_ajusta_stock(p_id_producto IN NUMBER, p_delta IN NUMBER) IS
BEGIN
  UPDATE inventario
  SET stock_actual = stock_actual + p_delta
  WHERE id_producto = p_id_producto;

  IF SQL%ROWCOUNT = 0 THEN
    INSERT INTO inventario (id_producto, stock_actual, stock_minimo)
    VALUES (p_id_producto, NVL(p_delta,0), 0);
  END IF;
END;
/

-- Recalcular totales al cambiar detalles (compras)
CREATE OR REPLACE TRIGGER trg_fc_det_recalc
FOR INSERT OR UPDATE OR DELETE ON factura_compra_detalle
COMPOUND TRIGGER
  TYPE t_set IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER; -- set de IDs
  g_ids t_set;

  PROCEDURE mark(p NUMBER) IS
  BEGIN
    IF p IS NOT NULL THEN
      g_ids(p) := 1; -- marcar presencia
    END IF;
  END;

  AFTER EACH ROW IS
  BEGIN
    IF INSERTING OR UPDATING THEN
      mark(:NEW.id_factura_compra);
    END IF;
    IF UPDATING OR DELETING THEN
      mark(:OLD.id_factura_compra);
    END IF;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    k PLS_INTEGER;
  BEGIN
    k := g_ids.FIRST;
    WHILE k IS NOT NULL LOOP
      pr_recalc_fc(k);
      k := g_ids.NEXT(k);
    END LOOP;
  END AFTER STATEMENT;
END;
/

-- Recalcular totales al cambiar detalles (ventas)
CREATE OR REPLACE TRIGGER trg_bol_det_recalc
FOR INSERT OR UPDATE OR DELETE ON boleta_venta_detalle
COMPOUND TRIGGER
  TYPE t_set IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER; -- set de IDs
  g_ids t_set;

  PROCEDURE mark(p NUMBER) IS
  BEGIN
    IF p IS NOT NULL THEN
      g_ids(p) := 1;
    END IF;
  END;

  AFTER EACH ROW IS
  BEGIN
    IF INSERTING OR UPDATING THEN
      mark(:NEW.id_boleta);
    END IF;
    IF UPDATING OR DELETING THEN
      mark(:OLD.id_boleta);s
    END IF;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    k PLS_INTEGER;
  BEGIN
    k := g_ids.FIRST;
    WHILE k IS NOT NULL LOOP
      pr_recalc_bol(k);
      k := g_ids.NEXT(k);
    END LOOP;
  END AFTER STATEMENT;
END;
/

-- Movimiento de stock al cambiar estado de FACTURA_COMPRA
CREATE OR REPLACE TRIGGER trg_fc_estado_stock
AFTER UPDATE OF estado ON factura_compra
FOR EACH ROW
BEGIN
  -- BORRADOR -> REGISTRADA : suma stock
  IF :NEW.estado = 'REGISTRADA' AND NVL(:OLD.estado,'BORRADOR') <> 'REGISTRADA' THEN
    FOR r IN (SELECT id_producto, cantidad FROM factura_compra_detalle WHERE id_factura_compra = :NEW.id_factura_compra) LOOP
      pr_ajusta_stock(r.id_producto, r.cantidad);
    END LOOP;
  END IF;

  -- REGISTRADA -> ANULADA : revierte stock
  IF :NEW.estado = 'ANULADA' AND :OLD.estado = 'REGISTRADA' THEN
    FOR r IN (SELECT id_producto, cantidad FROM factura_compra_detalle WHERE id_factura_compra = :NEW.id_factura_compra) LOOP
      pr_ajusta_stock(r.id_producto, -r.cantidad);
    END LOOP;
  END IF;
END;
/

-- Movimiento de stock al cambiar estado de BOLETA_VENTA
CREATE OR REPLACE TRIGGER trg_bol_estado_stock
AFTER UPDATE OF estado ON boleta_venta
FOR EACH ROW
BEGIN
  -- CREADA -> PAGADA : descuenta stock
  IF :NEW.estado = 'PAGADA' AND NVL(:OLD.estado,'CREADA') <> 'PAGADA' THEN
    FOR r IN (SELECT id_producto, cantidad FROM boleta_venta_detalle WHERE id_boleta = :NEW.id_boleta) LOOP
      pr_ajusta_stock(r.id_producto, -r.cantidad);
    END LOOP;
  END IF;

  -- PAGADA -> ANULADA : repone stock
  IF :NEW.estado = 'ANULADA' AND :OLD.estado = 'PAGADA' THEN
    FOR r IN (SELECT id_producto, cantidad FROM boleta_venta_detalle WHERE id_boleta = :NEW.id_boleta) LOOP
      pr_ajusta_stock(r.id_producto, r.cantidad);
    END LOOP;
  END IF;
END;
/

-- Historial de precios: registrar cambios en PRODUCTO (costo/precio)
CREATE OR REPLACE TRIGGER trg_producto_hist_precio
AFTER UPDATE OF costo, precio ON producto
FOR EACH ROW
BEGIN
  IF NVL(:OLD.costo,-1) <> NVL(:NEW.costo,-1) THEN
    INSERT INTO producto_precio_hist (id_producto, tipo, precio, vigente_desde, usuario_registra)
    VALUES (:NEW.id_producto, 'COSTO', :NEW.costo, TRUNC(SYSDATE), USER);
  END IF;
  IF NVL(:OLD.precio,-1) <> NVL(:NEW.precio,-1) THEN
    INSERT INTO producto_precio_hist (id_producto, tipo, precio, vigente_desde, usuario_registra)
    VALUES (:NEW.id_producto, 'VENTA', :NEW.precio, TRUNC(SYSDATE), USER);
  END IF;
END;
/
