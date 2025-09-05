-- Parámetro IVA (idempotente)
MERGE INTO parametro_sistema t
USING (SELECT 'IVA' codigo, 0.19 valor_num, 'Impuesto IVA Chile' descripcion FROM dual) s
ON (t.codigo = s.codigo)
WHEN MATCHED THEN UPDATE SET t.valor_num = s.valor_num, t.descripcion = s.descripcion
WHEN NOT MATCHED THEN INSERT (codigo, valor_num, descripcion)
VALUES (s.codigo, s.valor_num, s.descripcion);

-- Roles (idempotente por nombre)
MERGE INTO rol t
USING (SELECT 'ADMIN' nombre FROM dual UNION ALL SELECT 'VENTAS' FROM dual) s
ON (t.nombre = s.nombre)
WHEN NOT MATCHED THEN INSERT (nombre) VALUES (s.nombre);

-- Usuarios (idempotente por username; toma id_rol por nombre)
MERGE INTO usuario t
USING (
  SELECT 'AdminPYM' username, 'hash_1234' password_hash, 'Administrador PyME' nombre,
         (SELECT id_rol FROM rol WHERE nombre='ADMIN') id_rol FROM dual
  UNION ALL
  SELECT 'Ventas',   'hash_1234',       'Vendedor',
         (SELECT id_rol FROM rol WHERE nombre='VENTAS') FROM dual
) s
ON (t.username = s.username)
WHEN MATCHED THEN UPDATE SET t.password_hash = s.password_hash, t.nombre = s.nombre, t.id_rol = s.id_rol
WHEN NOT MATCHED THEN INSERT (username, password_hash, nombre, id_rol)
VALUES (s.username, s.password_hash, s.nombre, s.id_rol);

-- Proveedor demo (idempotente por RUT normalizado)
MERGE INTO proveedor t
USING (
  SELECT '76.543.210-9' rut, 'Gas Mayorista Ltda.' razon_social, 'Distribución de gas' giro,
         '+56 2 2345 6789' telefono, 'contacto@gasmayor.cl' email, 'Santiago' direccion, 'S' activo
  FROM dual
) s
ON (t.rut = s.rut)
WHEN MATCHED THEN UPDATE SET
  t.razon_social = s.razon_social, t.giro = s.giro, t.telefono = s.telefono,
  t.email = s.email, t.direccion = s.direccion, t.activo = s.activo,
  t.fecha_actualizacion = SYSTIMESTAMP, t.actualizado_por = USER
WHEN NOT MATCHED THEN INSERT (rut, razon_social, giro, telefono, email, direccion, activo)
VALUES (s.rut, s.razon_social, s.giro, s.telefono, s.email, s.direccion, s.activo);

-- Productos (idempotente por SKU)
MERGE INTO producto t
USING (
  SELECT 'GAS-5'  sku, 'Cilindro Gas 5 Kg'  nombre, '5KG'  formato, 'UN' unidad_medida,  8000 costo, 10500 precio, NULL imagen_url, 'S' activo FROM dual UNION ALL
  SELECT 'GAS-11'     , 'Cilindro Gas 11 Kg', '11KG', 'UN', 14000, 18500, NULL, 'S' FROM dual UNION ALL
  SELECT 'GAS-15'     , 'Cilindro Gas 15 Kg', '15KG', 'UN', 18000, 23500, NULL, 'S' FROM dual UNION ALL
  SELECT 'GAS-45'     , 'Cilindro Gas 45 Kg', '45KG', 'UN', 52000, 68000, NULL, 'S' FROM dual UNION ALL
  SELECT 'GAS-VMF'    , 'Cilindro Gas VMF'  , 'VMF' , 'UN', 20000, 26000, NULL, 'S' FROM dual UNION ALL
  SELECT 'GAS-VMA'    , 'Cilindro Gas VMA'  , 'VMA' , 'UN', 21000, 27000, NULL, 'S' FROM dual
) s
ON (t.sku = s.sku)
WHEN MATCHED THEN UPDATE SET
  t.nombre = s.nombre, t.formato = s.formato, t.unidad_medida = s.unidad_medida,
  t.costo = s.costo, t.precio = s.precio, t.imagen_url = s.imagen_url, t.activo = s.activo,
  t.fecha_actualizacion = SYSTIMESTAMP, t.actualizado_por = USER
WHEN NOT MATCHED THEN INSERT (sku, nombre, formato, unidad_medida, costo, precio, imagen_url, activo)
VALUES (s.sku, s.nombre, s.formato, s.unidad_medida, s.costo, s.precio, s.imagen_url, s.activo);

-- Inventario inicial (1 fila por producto; crea si no existe, y asegura mínimo 5 si es NULL)
MERGE INTO inventario t
USING (SELECT id_producto FROM producto) s
ON (t.id_producto = s.id_producto)
WHEN MATCHED THEN UPDATE SET t.stock_minimo = COALESCE(t.stock_minimo, 5)
WHEN NOT MATCHED THEN INSERT (id_producto, stock_actual, stock_minimo)
VALUES (s.id_producto, 0, 5);

-- Cliente “Consumidor Final” (solo si NO existe ya uno sin RUT con ese nombre)
INSERT INTO cliente (rut, nombre, telefono, email, direccion)
SELECT NULL, 'Consumidor Final', NULL, NULL, NULL
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM cliente WHERE rut IS NULL AND nombre = 'Consumidor Final'
);
