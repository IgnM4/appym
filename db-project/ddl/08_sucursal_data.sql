DECLARE
  v_id NUMBER;
BEGIN
  INSERT INTO sucursal(nombre, direccion, ciudad)
  VALUES ('Casa Matriz', NULL, 'Santiago')
  RETURNING id_sucursal INTO v_id;

  UPDATE inventario
     SET id_sucursal = v_id
   WHERE id_sucursal IS NULL;
END;
/
