-- 29_venta_idempotencia.sql
-- Asegura columna/flag, normaliza histórico, índices de unicidad y procedure idempotente

--------------------------------------------------------------------------------
-- 1) Columna inventario_impactado si no existe
--------------------------------------------------------------------------------
DECLARE
  v_cnt PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_cnt
  FROM user_tab_columns
  WHERE table_name = 'BOLETA_VENTA'
    AND column_name = 'INVENTARIO_IMPACTADO';

  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE
      'ALTER TABLE boleta_venta
         ADD (inventario_impactado CHAR(1) DEFAULT ''N'' NOT NULL
              CHECK (inventario_impactado IN (''S'',''N'')))';
  END IF;
END;
/

--------------------------------------------------------------------------------
-- 2) Marcar boletas ya impactadas por movimientos VENTA
--------------------------------------------------------------------------------
UPDATE boleta_venta b
   SET inventario_impactado = 'S'
 WHERE NVL(inventario_impactado,'N') <> 'S'
   AND EXISTS (
     SELECT 1
       FROM movimiento_stock m
      WHERE m.ref_tipo = 'VENTA'
        AND m.ref_id   = b.id_boleta
   )
/

--------------------------------------------------------------------------------
-- 3) Índice único para no duplicar movimientos VENTA
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE
    'CREATE UNIQUE INDEX uq_mov_venta_unico
       ON movimiento_stock (
         CASE WHEN ref_tipo = ''VENTA'' THEN ref_id       END,
         CASE WHEN ref_tipo = ''VENTA'' THEN id_producto  END,
         CASE WHEN ref_tipo = ''VENTA'' THEN tipo         END,
         CASE WHEN ref_tipo = ''VENTA'' THEN es_lleno     END
       )';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF; -- ya existe
END;
/

--------------------------------------------------------------------------------
-- 4) Índice único: un pendiente activo por cliente/producto
--------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE
    'CREATE UNIQUE INDEX uq_pend_vacio_activo
       ON pendiente_vacio (
         CASE WHEN resuelto = ''N'' THEN id_cliente  END,
         CASE WHEN resuelto = ''N'' THEN id_producto END
       )';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF; -- ya existe
END;
/

--------------------------------------------------------------------------------
-- 5) Procedure idempotente
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_registrar_venta(p_id_boleta IN NUMBER) IS
  v_cliente NUMBER;
  v_origen  NUMBER;
  v_flag    CHAR(1);
  v_disp    NUMBER;
BEGIN
  -- Tomar boleta y bloquear fila (evita doble impacto concurrente)
  BEGIN
    SELECT id_cliente,
           origen_ubicacion,
           NVL(inventario_impactado,'N')
      INTO v_cliente, v_origen, v_flag
      FROM boleta_venta
     WHERE id_boleta = p_id_boleta
     FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe boleta '||p_id_boleta);
  END;

  -- Idempotencia: ya impactada -> salir
  IF v_flag = 'S' THEN
    RETURN;
  END IF;

  -- Por cada línea de detalle
  FOR r IN (
    SELECT id_producto, cantidad
      FROM boleta_venta_detalle
     WHERE id_boleta = p_id_boleta
  ) LOOP
    -- Stock disponible en origen (si no hay fila, 0)
    BEGIN
      SELECT NVL(llenos,0)
        INTO v_disp
        FROM stock_ubicacion
       WHERE id_ubicacion = v_origen
         AND id_producto  = r.id_producto
       FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_disp := 0;
    END;

    IF v_disp < r.cantidad THEN
      RAISE_APPLICATION_ERROR(
        -20001,
        'Stock insuficiente en origen para producto '||r.id_producto||
        ' (disp='||v_disp||', req='||r.cantidad||')'
      );
    END IF;

    -- Descontar stock
    UPDATE stock_ubicacion
       SET llenos = llenos - r.cantidad,
           fecha_actualizacion = SYSTIMESTAMP
     WHERE id_ubicacion = v_origen
       AND id_producto  = r.id_producto;

    -- Movimiento VENTA (resiliente ante reintentos)
    BEGIN
      INSERT INTO movimiento_stock
        (fecha, tipo, id_ubicacion_desde, id_producto, cantidad, es_lleno, ref_tipo, ref_id)
      VALUES
        (SYSTIMESTAMP, 'VENTA', v_origen, r.id_producto, r.cantidad, 'S', 'VENTA', p_id_boleta);
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    -- Pendiente de vacío idempotente (una fila activa por cliente/producto)
    MERGE INTO pendiente_vacio p
    USING (
      SELECT v_cliente     AS id_cliente,
             r.id_producto AS id_producto,
             r.cantidad    AS cantidad
      FROM dual
    ) s
      ON ( p.id_cliente = s.id_cliente
       AND p.id_producto = s.id_producto
       AND p.resuelto   = 'N')
    WHEN MATCHED THEN
      UPDATE SET p.cantidad = p.cantidad + s.cantidad
    WHEN NOT MATCHED THEN
      INSERT (id_cliente, id_producto, cantidad, resuelto)
      VALUES (s.id_cliente, s.id_producto, s.cantidad, 'N');
  END LOOP;

  -- Marcar boleta como impactada
  UPDATE boleta_venta
     SET inventario_impactado = 'S'
   WHERE id_boleta = p_id_boleta;

  COMMIT;
END;
/
