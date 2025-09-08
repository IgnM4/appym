SET PAGESIZE 200 LINESIZE 200
COLUMN estado FORMAT A12

PROMPT == Conteos base ==
SELECT 
  (SELECT COUNT(*) FROM producto)       AS productos,
  (SELECT COUNT(*) FROM boleta_venta)   AS boletas,
  (SELECT COUNT(*) FROM boleta_item)    AS items
FROM dual;

PROMPT == Estados en BOLETA_VENTA ==
SELECT estado, COUNT(*) 
FROM boleta_venta 
GROUP BY estado 
ORDER BY 1;

PROMPT == Join sin filtro ==
SELECT COUNT(*) AS filas 
FROM boleta_item vi 
JOIN boleta_venta b ON b.id_boleta = vi.id_boleta;

PROMPT == Join con estado='PAGADA' ==
SELECT COUNT(*) AS filas 
FROM boleta_item vi 
JOIN boleta_venta b ON b.id_boleta = vi.id_boleta
WHERE b.estado = 'PAGADA';

PROMPT == Refresh MV ==
BEGIN 
  DBMS_MVIEW.REFRESH('MV_VENTAS_POR_PRODUCTO','C');
END;
/

PROMPT == Filas en MV ==
SELECT COUNT(*) AS filas FROM MV_VENTAS_POR_PRODUCTO;

PROMPT == Top 5 de MV ==
SELECT * 
FROM MV_VENTAS_POR_PRODUCTO
FETCH FIRST 5 ROWS ONLY;
