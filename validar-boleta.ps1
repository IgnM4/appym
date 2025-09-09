# validar-boleta.ps1

# --- Config ---
$SqlPlus = "sqlplus"
$User    = "APP_PYME"
$ConnStr = "localhost:1521/XEPDB1"

# --- Password seguro ---
$Secure  = Read-Host "Password for $User" -AsSecureString
$Plain   = (New-Object System.Net.NetworkCredential("", $Secure)).Password

# --- SQL a ejecutar ---
$SQL = @"
whenever sqlerror exit failure rollback
set serveroutput on linesize 200 pagesize 200 trimspool on
set numformat 999G999G999D00

connect $User/"$Plain"@$ConnStr

prompt == id_boleta a validar ==
VAR v NUMBER
BEGIN
  SELECT MAX(id_boleta) INTO :v FROM boleta_venta;
END;
/
PRINT v

prompt == 1) Detalle con SKU y nombre ==
COLUMN sku             FORMAT A12
COLUMN nombre          FORMAT A40
COLUMN cantidad        FORMAT 999G999D00
COLUMN precio_unitario FORMAT 999G999G999
COLUMN descuento       FORMAT 999G999G999
COLUMN subtotal        FORMAT 999G999G999
SELECT d.id_boleta, p.sku, p.nombre,
       d.cantidad, d.precio_unitario, d.descuento, d.subtotal
FROM   boleta_venta_detalle d
JOIN   producto p ON p.id_producto = d.id_producto
WHERE  d.id_boleta = :v
ORDER  BY d.id_producto;

prompt == 2) Suma del detalle vs cabecera ==
COLUMN sum_detalle FORMAT 999G999G999
COLUMN neto        FORMAT 999G999G999
COLUMN iva         FORMAT 999G999G999
COLUMN total       FORMAT 999G999G999
COLUMN diff_neto   FORMAT 999G999G999
COLUMN diff_total  FORMAT 999G999G999
SELECT b.id_boleta,
       SUM(d.cantidad*d.precio_unitario - d.descuento) AS sum_detalle,
       b.neto, b.iva, b.total,
       (b.neto  - SUM(d.cantidad*d.precio_unitario - d.descuento)) AS diff_neto,
       (b.total - (b.neto + b.iva))                               AS diff_total
FROM   boleta_venta b
JOIN   boleta_venta_detalle d ON d.id_boleta = b.id_boleta
WHERE  b.id_boleta = :v
GROUP BY b.id_boleta, b.neto, b.iva, b.total;

prompt == 3) Validación booleana ==
SELECT CASE
         WHEN b.neto = SUM(d.cantidad*d.precio_unitario - d.descuento)
          AND b.total = b.neto + b.iva
         THEN 'OK' ELSE 'MISMATCH'
       END AS comprobacion
FROM   boleta_venta b
JOIN   boleta_venta_detalle d ON d.id_boleta = b.id_boleta
WHERE  b.id_boleta = :v
GROUP BY b.id_boleta, b.neto, b.iva, b.total;

prompt == 4) Vendedor seteado por trigger ==
SELECT id_boleta, id_usuario_vende
FROM   boleta_venta
WHERE  id_boleta = :v;

prompt == 5) Líneas desalineadas (si hay) ==
SELECT d.*
FROM   boleta_venta_detalle d
WHERE  d.id_boleta = :v
AND    d.subtotal <> (d.cantidad*d.precio_unitario - d.descuento);

prompt == 6) Estado de MV (opcional) ==
SELECT mview_name, staleness, last_refresh_date
FROM   user_mviews
WHERE  mview_name = 'MV_VENTAS_POR_PRODUCTO';

exit
"@

# --- Ejecutar ---
$SQL | & $SqlPlus -s /nolog
