-- Verificaciones operativas básicas de stock y ventas
-- 
-- Inventario actual por producto
SELECT p.sku,
       p.nombre,
       i.stock_actual
  FROM producto p
  JOIN inventario i ON i.id_producto = p.id_producto
 ORDER BY p.sku;

-- Últimos movimientos de compras y ventas
SELECT *
  FROM (
        SELECT fc.fecha,
               fc.numero AS referencia,
               'COMPRA' AS tipo,
               SUM(fcd.cantidad) AS cantidad
          FROM factura_compra fc
          JOIN factura_compra_detalle fcd ON fcd.id_factura_compra = fc.id_factura_compra
         GROUP BY fc.fecha, fc.numero
         ORDER BY fc.fecha DESC
       )
 WHERE ROWNUM <= 5
UNION ALL
SELECT *
  FROM (
        SELECT bv.fecha,
               bv.numero,
               'VENTA' AS tipo,
               SUM(bvd.cantidad) AS cantidad
          FROM boleta_venta bv
          JOIN boleta_venta_detalle bvd ON bvd.id_boleta = bv.id_boleta
         GROUP BY bv.fecha, bv.numero
         ORDER BY bv.fecha DESC
       )
 WHERE ROWNUM <= 5;

-- Ventas pagadas del día por método de pago
SELECT metodo_pago,
       SUM(total) AS total_dia
  FROM boleta_venta
 WHERE estado = 'PAGADA'
   AND fecha = TRUNC(SYSDATE)
 GROUP BY metodo_pago;
