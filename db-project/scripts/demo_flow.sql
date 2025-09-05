-- DEMO: compra REGISTRADA (sube stock) → venta PAGADA (baja stock) → KPIs

-- 1) Crear factura de compra (BORRADOR)
INSERT INTO factura_compra (id_proveedor, numero, fecha, direccion_entrega, id_usuario_registra, estado)
SELECT p.id_proveedor, 'FC-0001', TRUNC(SYSDATE), 'Bodega Central', u.id_usuario, 'BORRADOR'
FROM proveedor p
CROSS JOIN usuario u
WHERE p.rut = '76.543.210-9' AND u.username = 'AdminPYM';

-- 2) Agregar detalle (11kg x 10 unidades a costo actual)
INSERT INTO factura_compra_detalle (id_factura_compra, id_producto, cantidad, costo_unitario)
SELECT fc.id_factura_compra, pr.id_producto, 10, pr.costo
FROM factura_compra fc
JOIN producto pr ON pr.sku = 'GAS-11'
WHERE fc.numero = 'FC-0001';

-- 3) Cambiar estado a REGISTRADA (triggers suman stock y recalculan totales)
UPDATE factura_compra SET estado = 'REGISTRADA'
WHERE numero = 'FC-0001';

COMMIT;

-- Ver stock
SELECT p.sku, p.nombre, i.stock_actual
FROM producto p JOIN inventario i ON i.id_producto = p.id_producto
WHERE p.sku = 'GAS-11';

-- 4) Crear boleta (CREADA) por Vendedor
INSERT INTO boleta_venta (numero, fecha, id_usuario_vende, estado, metodo_pago)
SELECT 'BOL-0001', TRUNC(SYSDATE), u.id_usuario, 'CREADA', 'EFECTIVO'
FROM usuario u WHERE u.username = 'Ventas';

-- 5) Agregar detalle (11kg x 3 a precio venta)
INSERT INTO boleta_venta_detalle (id_boleta, id_producto, cantidad, precio_unitario, descuento)
SELECT b.id_boleta, p.id_producto, 3, p.precio, 0
FROM boleta_venta b
JOIN producto p ON p.sku = 'GAS-11'
WHERE b.numero = 'BOL-0001';

-- 6) Pagar (PAGADA) → stock baja, totales recalculados
UPDATE boleta_venta SET estado = 'PAGADA' WHERE numero = 'BOL-0001';
COMMIT;

-- Stock tras la venta
SELECT p.sku, p.nombre, i.stock_actual
FROM producto p JOIN inventario i ON i.id_producto = p.id_producto
WHERE p.sku = 'GAS-11';

-- KPIs
SELECT * FROM v_ventas_diarias WHERE dia = TRUNC(SYSDATE);
SELECT * FROM v_compras_vs_ventas_dia WHERE dia = TRUNC(SYSDATE);
SELECT * FROM v_ventas_por_producto WHERE sku = 'GAS-11';

-- Verificaciones adicionales
@check_operativo.sql
