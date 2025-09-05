-- Ventas con origen de ubicacion

-- 1) Obtener id de LOCAL y asegurar columna
DECLARE
  v_local_id NUMBER;
BEGIN
  SELECT id_ubicacion INTO v_local_id
  FROM ubicacion
  WHERE nombre = 'LOCAL';

  -- Agregar columna si no existe
  BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE boleta_venta ADD (origen_ubicacion NUMBER)';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE != -1430 THEN RAISE; END IF; -- ORA-01430: column exists
  END;
END;
/

-- 2) Inicializar la columna (dinámico para que compile aunque la columna no existiera antes)
DECLARE
  v_local_id NUMBER;
BEGIN
  SELECT id_ubicacion INTO v_local_id
  FROM ubicacion
  WHERE nombre = 'LOCAL';

  EXECUTE IMMEDIATE
    'UPDATE boleta_venta
        SET origen_ubicacion = :1
      WHERE origen_ubicacion IS NULL'
    USING v_local_id;
END;
/

-- 3) Default + NOT NULL (dinámico, tolerante)
DECLARE
  v_local_id NUMBER;
BEGIN
  SELECT id_ubicacion INTO v_local_id
  FROM ubicacion
  WHERE nombre = 'LOCAL';

  BEGIN
    EXECUTE IMMEDIATE
      'ALTER TABLE boleta_venta MODIFY (origen_ubicacion NUMBER DEFAULT '||v_local_id||' NOT NULL)';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE != -1442 THEN RAISE; END IF; -- ya tenía NN/DEFAULT
  END;
END;
/

-- 4) FK (dinámico, tolerante)
BEGIN
  BEGIN
    EXECUTE IMMEDIATE
      'ALTER TABLE boleta_venta
         ADD CONSTRAINT fk_boleta__origen_ubi
             FOREIGN KEY (origen_ubicacion)
             REFERENCES ubicacion(id_ubicacion)';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE != -2275 THEN RAISE; END IF; -- FK ya existía
  END;
END;
/

-- 5) (recrear procedure)

BEGIN
  EXECUTE IMMEDIATE 'DROP PROCEDURE pr_registrar_venta';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -4043 THEN RAISE; END IF; -- no existe
END;
/

CREATE OR REPLACE PROCEDURE pr_registrar_venta(p_id_boleta IN NUMBER) IS
  v_origen   NUMBER;
  v_cliente  NUMBER;
BEGIN
  SELECT origen_ubicacion, id_cliente
    INTO v_origen, v_cliente
    FROM boleta_venta
   WHERE id_boleta = p_id_boleta;

  FOR r IN (
    SELECT id_producto, cantidad
      FROM boleta_venta_detalle
     WHERE id_boleta = p_id_boleta
  ) LOOP
    MERGE INTO stock_ubicacion su
    USING dual
      ON (su.id_ubicacion = v_origen AND su.id_producto = r.id_producto)
    WHEN MATCHED THEN
      UPDATE SET su.llenos = su.llenos - r.cantidad,
                 su.fecha_actualizacion = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
      INSERT (id_ubicacion, id_producto, llenos, vacios, fecha_actualizacion)
      VALUES (v_origen, r.id_producto, -r.cantidad, 0, SYSTIMESTAMP);

    INSERT INTO movimiento_stock (fecha, tipo, id_ubicacion_desde, id_producto, cantidad, es_lleno, ref_tipo, ref_id)
    VALUES (SYSTIMESTAMP, 'VENTA', v_origen, r.id_producto, r.cantidad, 'S', 'VENTA', p_id_boleta);

    IF v_cliente IS NOT NULL THEN
      INSERT INTO pendiente_vacio (id_cliente, id_producto, cantidad, fecha_entrega)
      VALUES (v_cliente, r.id_producto, r.cantidad, TRUNC(SYSDATE));
    END IF;
  END LOOP;
END;
/
