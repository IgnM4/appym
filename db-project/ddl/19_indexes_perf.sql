-- 19_indexes_perf.sql (idempotente, bloque único para Liquibase/JDBC)
DECLARE
  PROCEDURE try_create(p_sql IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_sql;
  EXCEPTION
    WHEN OTHERS THEN
      -- -955: nombre ya usado por un objeto existente
      -- -1408: ya existe un índice con esa lista de columnas
      IF SQLCODE NOT IN (-955, -1408) THEN
        RAISE;
      END IF;
  END;
BEGIN
  try_create('CREATE INDEX ix_boleta_venta__estado_fecha ON boleta_venta(estado, fecha)');
  try_create('CREATE INDEX ix_bv_detalle__id_producto ON boleta_venta_detalle(id_producto)');
  try_create('CREATE INDEX ix_producto__sku ON producto(sku)');
END;
