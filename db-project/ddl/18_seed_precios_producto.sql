MERGE INTO producto p
USING (
  SELECT 'GAS-5'  sku, 'Cilindro Gas 5 Kg'  nombre, 10811 costo, 13300 precio FROM dual UNION ALL
  SELECT 'GAS-11' sku, 'Cilindro Gas 11 Kg' nombre, 22340 costo, 25000 precio FROM dual UNION ALL
  SELECT 'GAS-15' sku, 'Cilindro Gas 15 Kg' nombre, 21354 costo, 26000 precio FROM dual UNION ALL
  SELECT 'GAS-45' sku, 'Cilindro Gas 45 Kg' nombre, 82297 costo, 91500 precio FROM dual UNION ALL
  SELECT 'GAS-VMF' sku,'Cilindro Gas VMF'   nombre, 31479 costo, 35000 precio FROM dual UNION ALL
  SELECT 'GAS-VMA' sku,'Cilindro Gas VMA'   nombre, 32379 costo, 36000 precio FROM dual
) s
ON (p.sku = s.sku)
WHEN MATCHED THEN
  UPDATE SET p.costo  = s.costo,
             p.precio = s.precio
WHEN NOT MATCHED THEN
  INSERT (sku, nombre, costo, precio)
  VALUES (s.sku, s.nombre, s.costo, s.precio);
