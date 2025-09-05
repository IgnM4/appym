-- ddl/13b_export_procs.sql
CREATE OR REPLACE PROCEDURE pr_export_ventas_diarias(
  p_desde    DATE,
  p_hasta    DATE,
  p_filename VARCHAR2
) AS
  f UTL_FILE.FILE_TYPE;
BEGIN
  f := UTL_FILE.FOPEN('EXPORT_DIR', p_filename, 'w', 32767);
  UTL_FILE.PUT_LINE(f, 'dia,total_ventas,total_neto,total_iva');
  FOR r IN (
    SELECT TO_CHAR(dia,'YYYY-MM-DD') AS d,
           total_ventas, total_neto, total_iva
    FROM mv_ventas_diarias
    WHERE dia BETWEEN TRUNC(p_desde) AND TRUNC(p_hasta)
    ORDER BY dia
  ) LOOP
    UTL_FILE.PUT_LINE(f, r.d||','||r.total_ventas||','||r.total_neto||','||r.total_iva);
  END LOOP;
  UTL_FILE.FCLOSE(f);
END;
/

CREATE OR REPLACE PROCEDURE pr_export_ventas_por_producto(
  p_desde    DATE,
  p_hasta    DATE,
  p_filename VARCHAR2
) AS
  f UTL_FILE.FILE_TYPE;
BEGIN
  f := UTL_FILE.FOPEN('EXPORT_DIR', p_filename, 'w', 32767);
  UTL_FILE.PUT_LINE(f, 'sku,nombre,unidades_vendidas,monto_vendido,costo_estimado,utilidad_estimada');

  FOR r IN (
    SELECT p.sku, p.nombre,
           SUM(d.cantidad)                       AS unidades_vendidas,
           SUM(d.subtotal)                       AS monto_vendido,
           SUM(d.cantidad * p.costo)             AS costo_estimado,
           SUM(d.subtotal) - SUM(d.cantidad*p.costo) AS utilidad_estimada
    FROM boleta_venta_detalle d
    JOIN boleta_venta b ON b.id_boleta = d.id_boleta AND b.estado='PAGADA'
    JOIN producto p     ON p.id_producto = d.id_producto
    WHERE TRUNC(b.fecha) BETWEEN TRUNC(p_desde) AND TRUNC(p_hasta)
    GROUP BY p.sku, p.nombre
    ORDER BY p.sku
  ) LOOP
    UTL_FILE.PUT_LINE(f,
      r.sku||','||
      REPLACE(r.nombre,',',' ')||','||
      r.unidades_vendidas||','||
      r.monto_vendido||','||
      r.costo_estimado||','||
      r.utilidad_estimada
    );
  END LOOP;

  UTL_FILE.FCLOSE(f);
END;
/
