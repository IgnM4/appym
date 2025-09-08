SET DEFINE OFF
SET PAGESIZE 200
SET LINESIZE 300
SET FEEDBACK ON

COLUMN now FORMAT A19
PROMPT == Fecha/Hora ==
SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') AS now FROM dual;

PROMPT
PROMPT == Objetos clave ==
COLUMN object_type FORMAT A20
COLUMN object_name FORMAT A35
COLUMN status FORMAT A12
SELECT object_type, object_name, status
FROM   user_objects
WHERE  object_name IN (
  'MV_VENTAS_POR_PRODUCTO','MV_VENTAS_DIARIAS',
  'IX_MV_VPP__SKU','V_KPI_VENTAS_POR_PRODUCTO','V_KPI_VENTAS_DIARIAS'
)
ORDER  BY 1,2;

PROMPT
PROMPT == Estado de MVs ==
COLUMN mview_name FORMAT A30
COLUMN compile_state FORMAT A12
COLUMN staleness FORMAT A12
SELECT mview_name, compile_state, staleness, last_refresh_date
FROM   user_mviews
WHERE  mview_name IN ('MV_VENTAS_POR_PRODUCTO','MV_VENTAS_DIARIAS');

PROMPT
PROMPT == Refresh (completo) de MVs ==
BEGIN
  DBMS_MVIEW.REFRESH('MV_VENTAS_POR_PRODUCTO','C'); -- COMPLETE
  DBMS_MVIEW.REFRESH('MV_VENTAS_DIARIAS','C');
END;
/

PROMPT
PROMPT == Cabeceras hoy (PAGADA) ==
COLUMN dia FORMAT A10
SELECT TO_CHAR(TRUNC(fecha),'YYYY-MM-DD') AS dia,
       COUNT(*) AS boletas,
       SUM(total) AS total
FROM   boleta_venta
WHERE  estado='PAGADA'
GROUP  BY TRUNC(fecha)
ORDER  BY 1 DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT
PROMPT == Detalle de hoy por SKU ==
COLUMN sku FORMAT A12
SELECT p.sku,
       SUM(d.cantidad) AS unidades,
       SUM(d.subtotal) AS monto
FROM   boleta_venta b
JOIN   boleta_venta_detalle d ON d.id_boleta=b.id_boleta
JOIN   producto p             ON p.id_producto=d.id_producto
WHERE  b.estado='PAGADA'
AND    TRUNC(b.fecha)=TRUNC(SYSDATE)
GROUP  BY p.sku
ORDER  BY p.sku;

PROMPT
PROMPT == Conteos en MVs ==
SELECT COUNT(*) AS filas_vpp  FROM MV_VENTAS_POR_PRODUCTO;
SELECT COUNT(*) AS filas_vdia FROM MV_VENTAS_DIARIAS;

PROMPT
PROMPT == KPI: Ventas por producto ==
SELECT * FROM V_KPI_VENTAS_POR_PRODUCTO
ORDER  BY sku;

PROMPT
PROMPT == KPI: Ventas diarias (?ltimos 7 d?as) ==
SELECT TO_CHAR(dia,'YYYY-MM-DD') AS dia,
       total_ventas, total_neto, total_iva
FROM   V_KPI_VENTAS_DIARIAS
WHERE  dia >= TRUNC(SYSDATE)-7
ORDER  BY dia DESC;

PROMPT
PROMPT == Objetos inv?lidos ==
SELECT object_type, object_name
FROM   user_objects
WHERE  status='INVALID'
ORDER  BY 1,2;

PROMPT
PROMPT == Errores en KPIs/MVs (si hay) ==
COLUMN name FORMAT A28
COLUMN type FORMAT A20
SELECT name, type, line, position, text
FROM   user_errors
WHERE  name IN ('V_KPI_VENTAS_POR_PRODUCTO','V_KPI_VENTAS_DIARIAS',
                'MV_VENTAS_POR_PRODUCTO','MV_VENTAS_DIARIAS')
ORDER  BY name, sequence;

EXIT
