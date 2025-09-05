SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Asegurar contexto de usuario
BEGIN
  pkg_app_ctx.set_usuario(1);
END;
/

VAR v_id_boleta NUMBER
COLUMN local_id NEW_VALUE local_id
SELECT id_ubicacion AS local_id
FROM ubicacion WHERE nombre='LOCAL';

-- Un producto y su precio vigente
COLUMN prod_id NEW_VALUE prod_id
COLUMN precio  NEW_VALUE precio
SELECT v.id_producto AS prod_id, v.precio_con_iva AS precio
FROM v_precio_actual v
WHERE ROWNUM=1;

-- Inserta boleta
INSERT INTO boleta_venta(
  numero, id_cliente, fecha, estado,
  id_usuario_vende, neto, iva, total, origen_ubicacion
)
VALUES(
  'B-DEMO-'||TO_CHAR(SYSTIMESTAMP,'YYYYMMDDHH24MISS'),
  1, SYSTIMESTAMP, 'PAGADA',
  1, 10000, 1900, 11900, &local_id
)
RETURNING id_boleta INTO :v_id_boleta;

-- Inserta detalle con fallback de nombre de columna de precio
DECLARE
  v_sql VARCHAR2(4000);
BEGIN
  BEGIN
    v_sql := 'INSERT INTO boleta_venta_detalle (id_boleta, id_producto, cantidad, precio)
              VALUES (:1,:2,:3,:4)';
    EXECUTE IMMEDIATE v_sql USING :v_id_boleta, &prod_id, 2, &precio;
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE = -904 THEN
      BEGIN
        v_sql := 'INSERT INTO boleta_venta_detalle (id_boleta, id_producto, cantidad, precio_unit)
                  VALUES (:1,:2,:3,:4)';
        EXECUTE IMMEDIATE v_sql USING :v_id_boleta, &prod_id, 2, &precio;
      EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -904 THEN
          v_sql := 'INSERT INTO boleta_venta_detalle (id_boleta, id_producto, cantidad, precio_unitario)
                    VALUES (:1,:2,:3,:4)';
          EXECUTE IMMEDIATE v_sql USING :v_id_boleta, &prod_id, 2, &precio;
        ELSE RAISE; END IF;
      END;
    ELSE RAISE; END IF;
  END;
END;
/

COMMIT;

-- Impacto inventario + pendiente vacío (idempotente)
BEGIN
  pr_registrar_venta(:v_id_boleta);
END;
/

PROMPT ==> Stock en LOCAL del producto
SELECT * FROM stock_ubicacion
WHERE id_ubicacion = &local_id AND id_producto = &prod_id;

PROMPT ==> Movimientos de la venta (no debe duplicar si ejecutas de nuevo)
SELECT tipo, id_ubicacion_desde, id_producto, cantidad, es_lleno, ref_tipo, ref_id,
       TO_CHAR(fecha,'YYYY-MM-DD HH24:MI') AS fecha
FROM movimiento_stock
WHERE ref_tipo='VENTA' AND ref_id=:v_id_boleta
ORDER BY fecha;

PROMPT ==> Pendiente de devolución activo para el cliente
SELECT * FROM v_pendiente_vacio_activo
WHERE id_cliente = (SELECT id_cliente FROM boleta_venta WHERE id_boleta=:v_id_boleta);

EXIT
