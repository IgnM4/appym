CREATE OR REPLACE VIEW v_kpi_ventas_diarias AS
SELECT
  dia,
  total_ventas,
  total_neto,
  total_iva
FROM mv_ventas_diarias;
