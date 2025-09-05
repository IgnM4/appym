SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

VAR v_id_compra NUMBER

-- Bodega destino: BODEGA 1
COLUMN bodega_id NEW_VALUE bodega_id
SELECT id_ubicacion AS bodega_id
FROM ubicacion WHERE nombre='BODEGA 1';

-- Un proveedor cualquiera (el primero)
COLUMN proveedor_id NEW_VALUE proveedor_id
SELECT id_proveedor AS proveedor_id
FROM proveedor WHERE ROWNUM=1;

-- Un producto cualquiera y su precio lista
COLUMN prod_id NEW_VALUE prod_id
COLUMN precio  NEW_VALUE precio
SELECT v.id_producto AS prod_id, v.precio_con_iva AS precio
FROM v_precio_actual v
WHERE ROWNUM=1;

INSERT INTO compra (
  nro_pedido, nro_factura, forma_pago, id_proveedor, fecha,
  id_ubicacion_destino, subtotal, iva, total
) VALUES (
  'P-DEMO-'||TO_CHAR(SYSTIMESTAMP,'YYYYMMDDHH24MISS'),
  'F-DEMO-'||TO_CHAR(SYSTIMESTAMP,'YYYYMMDDHH24MISS'),
  'TRANSFERENCIA', &proveedor_id, TRUNC(SYSDATE),
  &bodega_id, 10000, 1900, 11900
)
RETURNING id_compra INTO :v_id_compra;

INSERT INTO compra_det (id_compra, id_producto, cantidad, costo_unit_con_iva, costo_unit_sin_iva)
VALUES (:v_id_compra, &prod_id, 5, &precio, ROUND(&precio/1.19, 0));

COMMIT;

BEGIN
  pr_registrar_compra(:v_id_compra);
END;
/

PROMPT ==> Stock en BODEGA 1
SELECT * FROM stock_ubicacion
WHERE id_ubicacion = &bodega_id AND id_producto = &prod_id;

PROMPT ==> Movimientos de la compra
SELECT tipo, id_ubicacion_hasta, id_producto, cantidad, es_lleno, ref_tipo, ref_id,
       TO_CHAR(fecha,'YYYY-MM-DD HH24:MI') AS fecha
FROM movimiento_stock
WHERE ref_tipo='COMPRA' AND ref_id=:v_id_compra
ORDER BY fecha;

EXIT
