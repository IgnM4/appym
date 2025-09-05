-- MV de ventas diarias (no requiere QUERY REWRITE)
CREATE MATERIALIZED VIEW mv_ventas_diarias
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT TRUNC(b.fecha)            AS dia,
       SUM(b.total)              AS total_ventas,
       SUM(b.neto)               AS total_neto,
       SUM(b.iva)                AS total_iva
  FROM boleta_venta b
 WHERE b.estado = 'PAGADA'
 GROUP BY TRUNC(b.fecha)
/
-- Índice para acelerar consultas por día
CREATE INDEX ix_mv_ventas_diarias__dia ON mv_ventas_diarias(dia)
/
