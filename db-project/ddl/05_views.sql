-- IVA desde parámetros (si no existe, asume 0.19 en vistas)
-- Ventas por día (solo PAGADA)
CREATE OR REPLACE VIEW v_ventas_diarias AS
SELECT TRUNC(b.fecha) dia,
       SUM(b.total) total_ventas,
       SUM(b.neto)  total_neto,
       SUM(b.iva)   total_iva
FROM boleta_venta b
WHERE b.estado = 'PAGADA'
GROUP BY TRUNC(b.fecha);

-- Compras vs Ventas por día
CREATE OR REPLACE VIEW v_compras_vs_ventas_dia AS
WITH c AS (
  SELECT TRUNC(fecha) dia, SUM(total) compras_total
  FROM factura_compra
  WHERE estado = 'REGISTRADA'
  GROUP BY TRUNC(fecha)
),
v AS (
  SELECT TRUNC(fecha) dia, SUM(total) ventas_total
  FROM boleta_venta
  WHERE estado = 'PAGADA'
  GROUP BY TRUNC(fecha)
)
SELECT COALESCE(c.dia, v.dia) dia,
       NVL(c.compras_total,0) compras_total,
       NVL(v.ventas_total,0) ventas_total
FROM c FULL OUTER JOIN v ON c.dia = v.dia;

-- Stock bajo mínimo
CREATE OR REPLACE VIEW v_stock_bajo_minimo AS
SELECT p.id_producto, p.sku, p.nombre, i.stock_actual, i.stock_minimo
FROM producto p
JOIN inventario i ON i.id_producto = p.id_producto
WHERE i.stock_actual < i.stock_minimo;

-- Ventas por producto (unidades y monto) usando costo actual como aproximación de costo
CREATE OR REPLACE VIEW v_ventas_por_producto AS
SELECT d.id_producto,
       p.sku, p.nombre, p.formato,
       SUM(d.cantidad) unidades_vendidas,
       SUM(d.subtotal) monto_vendido,
       SUM(d.cantidad * p.costo) costo_estimado,
       SUM(d.subtotal) - SUM(d.cantidad * p.costo) utilidad_estimada
FROM boleta_venta_detalle d
JOIN boleta_venta b ON b.id_boleta = d.id_boleta AND b.estado = 'PAGADA'
JOIN producto p ON p.id_producto = d.id_producto
GROUP BY d.id_producto, p.sku, p.nombre, p.formato;

CREATE OR REPLACE VIEW v_boleta_header AS
SELECT b.id_boleta, b.numero, b.fecha, b.neto, b.iva, b.total, b.metodo_pago,
       b.estado, u.nombre AS vendedor, c.nombre AS cliente, c.rut AS rut_cliente
FROM boleta_venta b
JOIN usuario u ON u.id_usuario = b.id_usuario_vende
LEFT JOIN cliente c ON c.id_cliente = b.id_cliente;

CREATE OR REPLACE VIEW v_boleta_detalle AS
SELECT d.id_boleta, p.sku, p.nombre, p.formato,
       d.cantidad, d.precio_unitario, d.descuento, d.subtotal
FROM boleta_venta_detalle d
JOIN producto p ON p.id_producto = d.id_producto;
