SET SERVEROUTPUT ON
-- Elimina ?ndice si existiera (ignora error si no existe)
BEGIN
  EXECUTE IMMEDIATE 'DROP INDEX IX_MV_VPP__SKU';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE NOT IN (-1418 /*index no existe*/) THEN
    NULL; -- ignora
  END IF;
END;
/

-- Elimina la MV si existiera
BEGIN
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW MV_VENTAS_POR_PRODUCTO';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE NOT IN (-12003 /*MV no existe*/, -942 /*table/view no existe*/) THEN
    RAISE;
  END IF;
END;
/

-- Crea la MV consistente con tu modelo actual
CREATE MATERIALIZED VIEW MV_VENTAS_POR_PRODUCTO
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
  p.sku,
  p.nombre,
  SUM(d.cantidad)                              AS unidades_vendidas,
  SUM(d.subtotal)                              AS monto_vendido,
  SUM(d.cantidad * NVL(p.costo, 0))            AS costo_estimado,
  SUM(d.subtotal) - SUM(d.cantidad * NVL(p.costo, 0)) AS utilidad_estimada
FROM boleta_venta_detalle d
JOIN producto       p ON p.id_producto = d.id_producto
JOIN boleta_venta   b ON b.id_boleta   = d.id_boleta
WHERE b.estado = 'PAGADA'
GROUP BY p.sku, p.nombre
/

-- ?ndice por SKU
CREATE INDEX IX_MV_VPP__SKU ON MV_VENTAS_POR_PRODUCTO (SKU);

-- Refresh y verificaci?n r?pida
BEGIN
  DBMS_MVIEW.REFRESH('MV_VENTAS_POR_PRODUCTO','C');
END;
/
SET PAGESIZE 100
SELECT compile_state, staleness, last_refresh_date
FROM   user_mviews
WHERE  mview_name='MV_VENTAS_POR_PRODUCTO';

SELECT COUNT(*) AS filas FROM MV_VENTAS_POR_PRODUCTO;
