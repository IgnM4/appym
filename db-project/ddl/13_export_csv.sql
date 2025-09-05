-- Helper para comillas y nulls
CREATE OR REPLACE FUNCTION csv_str(p IN VARCHAR2)
RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
  IF p IS NULL THEN RETURN '""'; END IF;
  RETURN '"' || REPLACE(p, '"', '""') || '"';
END;
/

-- Formato numérico con punto decimal
CREATE OR REPLACE FUNCTION csv_num(p IN NUMBER)
RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
  IF p IS NULL THEN RETURN '""'; END IF;
  RETURN '"' || TO_CHAR(p, 'FM9999999990D00', 'NLS_NUMERIC_CHARACTERS=.,') || '"';
END;
/

-- ===== Export: Ventas diarias (por rango) =====
CREATE OR REPLACE PROCEDURE pr_export_ventas_diarias(
  p_desde    IN DATE,
  p_hasta    IN DATE,
  p_filename IN VARCHAR2 DEFAULT 'ventas_diarias.csv'
) IS
  f   UTL_FILE.FILE_TYPE;
BEGIN
  f := UTL_FILE.FOPEN('IMPORT_DIR', p_filename, 'w', 32767);
  UTL_FILE.PUT_LINE(f, 'dia,total_ventas,total_neto,total_iva');

  FOR r IN (
    SELECT TRUNC(b.fecha) dia,
           SUM(b.total) total_ventas,
           SUM(b.neto)  total_neto,
           SUM(b.iva)   total_iva
    FROM boleta_venta b
    WHERE b.estado = 'PAGADA'
      AND b.fecha >= TRUNC(p_desde)
      AND b.fecha <  TRUNC(p_hasta) + 1
    GROUP BY TRUNC(b.fecha)
    ORDER BY 1
  ) LOOP
    UTL_FILE.PUT_LINE(
      f,
      csv_str(TO_CHAR(r.dia, 'YYYY-MM-DD')) || ',' ||
      csv_num(r.total_ventas) || ',' ||
      csv_num(r.total_neto)   || ',' ||
      csv_num(r.total_iva)
    );
  END LOOP;

  UTL_FILE.FCLOSE(f);
END;
/
SHOW ERRORS

-- ===== Export: Ventas por producto (por rango) =====
CREATE OR REPLACE PROCEDURE pr_export_ventas_por_producto(
  p_desde    IN DATE,
  p_hasta    IN DATE,
  p_filename IN VARCHAR2 DEFAULT 'ventas_por_producto.csv'
) IS
  f   UTL_FILE.FILE_TYPE;
BEGIN
  f := UTL_FILE.FOPEN('IMPORT_DIR', p_filename, 'w', 32767);
  UTL_FILE.PUT_LINE(f, 'sku,nombre,unidades_vendidas,monto_vendido,costo_estimado,utilidad_estimada');

  FOR r IN (
    SELECT p.sku,
           p.nombre,
           SUM(d.cantidad)                         unidades_vendidas,
           SUM(d.subtotal)                         monto_vendido,
           SUM(d.cantidad * p.costo)               costo_estimado,
           SUM(d.subtotal) - SUM(d.cantidad*p.costo) utilidad_estimada
    FROM boleta_venta_detalle d
    JOIN boleta_venta b ON b.id_boleta = d.id_boleta AND b.estado = 'PAGADA'
    JOIN producto p     ON p.id_producto = d.id_producto
    WHERE b.fecha >= TRUNC(p_desde)
      AND b.fecha <  TRUNC(p_hasta) + 1
    GROUP BY p.sku, p.nombre
    ORDER BY p.sku
  ) LOOP
    UTL_FILE.PUT_LINE(
      f,
      csv_str(r.sku) || ',' ||
      csv_str(r.nombre) || ',' ||
      csv_num(r.unidades_vendidas) || ',' ||
      csv_num(r.monto_vendido) || ',' ||
      csv_num(r.costo_estimado) || ',' ||
      csv_num(r.utilidad_estimada)
    );
  END LOOP;

  UTL_FILE.FCLOSE(f);
END;
/
SHOW ERRORS
