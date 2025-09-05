CREATE OR REPLACE VIEW v_kpi_ventas_por_producto AS
SELECT
  sku,
  nombre,
  unidades_vendidas,
  monto_vendido,
  costo_estimado,
  utilidad_estimada
FROM mv_ventas_por_producto;
