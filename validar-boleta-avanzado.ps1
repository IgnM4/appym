param(
  [int]$IdBoleta,
  [double]$IvaRate = 0.19,
  [string]$SpoolPath
)

# --- Config ---
$SqlPlus = "sqlplus"
$User    = "APP_PYME"
$ConnStr = "localhost:1521/XEPDB1"

# --- Password seguro ---
$Secure  = Read-Host "Password for $User" -AsSecureString
$Plain   = (New-Object System.Net.NetworkCredential("", $Secure)).Password

# --- Salida (log) ---
if (-not $SpoolPath) {
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $SpoolPath = "validacion-boleta-$ts.log"
}

# --- Bloque para fijar el ID de boleta ---
if ($PSBoundParameters.ContainsKey('IdBoleta')) {
  $InitV = @"
VAR v NUMBER
BEGIN
  :v := $IdBoleta;
END;
/
"@
} else {
  $InitV = @"
VAR v NUMBER
BEGIN
  SELECT MAX(id_boleta) INTO :v FROM boleta_venta;
END;
/
"@
}

# --- Tasa IVA como número con cultura invariante ---
$IvaRateStr = $IvaRate.ToString([System.Globalization.CultureInfo]::InvariantCulture)

$InitIva = @"
VAR iva_rate NUMBER
BEGIN
  :iva_rate := $IvaRateStr;
END;
/
"@

# --- SQL principal ---
$SQL = @"
whenever oserror exit failure
whenever sqlerror exit failure
set serveroutput on linesize 200 pagesize 200 trimspool on
set numformat 999G999G999D00

connect APP_PYME/"app_pyme_pass"@localhost:1521/XEPDB1
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

connect $User/"$Plain"@$ConnStr
spool "$SpoolPath"

prompt == Inicialización ==
$InitV
$InitIva
print v

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

prompt == 7) IVA calculado vs cabecera ==
COLUMN iva_calc FORMAT 999G999G999
COLUMN diff_iva FORMAT 999G999G999
SELECT b.id_boleta, b.neto, b.iva,
       ROUND(b.neto * :iva_rate) AS iva_calc,
       b.iva - ROUND(b.neto * :iva_rate) AS diff_iva
FROM   boleta_venta b
WHERE  b.id_boleta = :v;

prompt == 8) Resumen final (falla si algo no cuadra) ==
DECLARE
  v_bad NUMBER := 0;
  v_tmp NUMBER;
BEGIN
  -- (a) Neto/total vs detalle
  SELECT CASE
           WHEN b.neto = SUM(d.cantidad*d.precio_unitario - d.descuento)
            AND b.total = b.neto + b.iva
           THEN 0 ELSE 1
         END
  INTO v_tmp
  FROM boleta_venta b
  JOIN boleta_venta_detalle d ON d.id_boleta = b.id_boleta
  WHERE b.id_boleta = :v
  GROUP BY b.id_boleta, b.neto, b.iva, b.total;
  v_bad := v_bad + v_tmp;

  -- (b) IVA coincide con tasa dada
  SELECT CASE WHEN ABS(b.iva - ROUND(b.neto * :iva_rate)) = 0 THEN 0 ELSE 1 END
  INTO v_tmp
  FROM boleta_venta b
  WHERE b.id_boleta = :v;
  v_bad := v_bad + v_tmp;

  -- (c) Vendedor no nulo
  SELECT CASE WHEN id_usuario_vende IS NOT NULL THEN 0 ELSE 1 END
  INTO v_tmp
  FROM boleta_venta
  WHERE id_boleta = :v;
  v_bad := v_bad + v_tmp;

  -- (d) No hay renglones desalineados
  SELECT COUNT(*)
  INTO v_tmp
  FROM boleta_venta_detalle d
  WHERE d.id_boleta = :v
    AND d.subtotal <> (d.cantidad*d.precio_unitario - d.descuento);
  v_bad := v_bad + CASE WHEN v_tmp = 0 THEN 0 ELSE 1 END;

  IF v_bad > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Validación avanzada: **FALLÓ** ('||v_bad||' chequeo(s))');
    RAISE_APPLICATION_ERROR(-20100, 'Validación avanzada: FALLÓ');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Validación avanzada: OK');
  END IF;
END;
/
spool off
exit
"@

# --- Ejecutar ---
$SQL | & $SqlPlus -s /nolog

# Tip: el código de salida será != 0 si alguna validación falló.
# Puedes revisar el log:
Write-Host "`nLog guardado en: $SpoolPath"
