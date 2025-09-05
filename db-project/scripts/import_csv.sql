-- Proveedores (UPSERT por RUT) — filtra cabecera
MERGE INTO proveedor p
USING (
  SELECT TRIM(rut) rut, razon_social, giro, telefono, email, direccion,
         CASE UPPER(NVL(activo,'S')) WHEN 'S' THEN 'S' ELSE 'N' END activo
  FROM ext_proveedores
  WHERE UPPER(TRIM(rut)) <> 'RUT'
) e
ON (p.rut = e.rut)
WHEN MATCHED THEN UPDATE SET
  p.razon_social=e.razon_social, p.giro=e.giro, p.telefono=e.telefono,
  p.email=e.email, p.direccion=e.direccion, p.activo=e.activo,
  p.fecha_actualizacion=SYSTIMESTAMP, p.actualizado_por=USER
WHEN NOT MATCHED THEN INSERT (rut, razon_social, giro, telefono, email, direccion, activo)
VALUES (e.rut, e.razon_social, e.giro, e.telefono, e.email, e.direccion, e.activo);

-- Productos (UPSERT por SKU) — filtra cabecera y acepta coma decimal
MERGE INTO producto p
USING (
  SELECT TRIM(sku) sku, nombre, formato, NVL(unidad_medida,'UN') unidad_medida,
         TO_NUMBER(REPLACE(costo,  ',', '.'))  costo,
         TO_NUMBER(REPLACE(precio, ',', '.'))  precio,
         imagen_url,
         CASE UPPER(NVL(activo,'S')) WHEN 'S' THEN 'S' ELSE 'N' END activo
  FROM ext_productos
  WHERE UPPER(TRIM(sku)) <> 'SKU'
) e
ON (p.sku = e.sku)
WHEN MATCHED THEN UPDATE SET
  p.nombre=e.nombre, p.formato=e.formato, p.unidad_medida=e.unidad_medida,
  p.costo=e.costo, p.precio=e.precio, p.imagen_url=e.imagen_url, p.activo=e.activo,
  p.fecha_actualizacion=SYSTIMESTAMP, p.actualizado_por=USER
WHEN NOT MATCHED THEN INSERT (sku, nombre, formato, unidad_medida, costo, precio, imagen_url, activo)
VALUES (e.sku, e.nombre, e.formato, e.unidad_medida, e.costo, e.precio, e.imagen_url, e.activo);

-- Clientes (UPSERT por RUT) — filtra cabecera
MERGE INTO cliente c
USING (
  SELECT NULLIF(TRIM(rut),'') rut, nombre, telefono, email, direccion,
         CASE UPPER(NVL(activo,'S')) WHEN 'S' THEN 'S' ELSE 'N' END activo
  FROM ext_clientes
  WHERE NVL(UPPER(TRIM(rut)),'') <> 'RUT'
) e
ON (c.rut = e.rut)
WHEN MATCHED THEN UPDATE SET
  c.nombre=e.nombre, c.telefono=e.telefono, c.email=e.email, c.direccion=e.direccion, c.activo=e.activo,
  c.fecha_actualizacion=SYSTIMESTAMP, c.actualizado_por=USER
WHEN NOT MATCHED THEN INSERT (rut, nombre, telefono, email, direccion, activo)
VALUES (e.rut, e.nombre, e.telefono, e.email, e.direccion, e.activo);

-- Stock inicial — filtra cabecera y acepta coma decimal
MERGE INTO inventario i
USING (
  SELECT p.id_producto,
         TO_NUMBER(REPLACE(s.stock_actual, ',', '.')) stock_actual,
         TO_NUMBER(REPLACE(NVL(s.stock_minimo,'0'), ',', '.')) stock_minimo
  FROM ext_stock_inicial s
  JOIN producto p ON p.sku = TRIM(s.sku)
  WHERE UPPER(TRIM(s.sku)) <> 'SKU'
) e
ON (i.id_producto = e.id_producto)
WHEN MATCHED THEN UPDATE SET
  i.stock_actual = e.stock_actual,
  i.stock_minimo = e.stock_minimo
WHEN NOT MATCHED THEN INSERT (id_producto, stock_actual, stock_minimo)
VALUES (e.id_producto, e.stock_actual, e.stock_minimo);

-- Precios masivos (opcional) — filtra cabecera y acepta coma decimal
MERGE INTO producto p
USING (
  SELECT TRIM(sku) sku, UPPER(tipo) tipo, TO_NUMBER(REPLACE(precio, ',', '.')) precio
  FROM ext_precios
  WHERE UPPER(TRIM(sku)) <> 'SKU' AND UPPER(TRIM(tipo)) <> 'TIPO'
) e
ON (p.sku = e.sku)
WHEN MATCHED THEN UPDATE SET
  p.costo  = CASE WHEN e.tipo='COSTO' THEN e.precio ELSE p.costo END,
  p.precio = CASE WHEN e.tipo='VENTA' THEN e.precio ELSE p.precio END,
  p.fecha_actualizacion=SYSTIMESTAMP, p.actualizado_por=USER;

COMMIT;
