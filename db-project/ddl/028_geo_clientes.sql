-- Geolocalización de clientes (idempotente)

-- lat
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE cliente ADD (lat NUMBER(9,6))';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN RAISE; END IF; -- ORA-01430: columna ya existe
END;
/

-- lng
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE cliente ADD (lng NUMBER(9,6))';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

-- geo_precision
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE cliente ADD (geo_precision VARCHAR2(30))';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

-- geo_at
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE cliente ADD (geo_at TIMESTAMP)';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

CREATE OR REPLACE PROCEDURE pr_upd_geocoords(
  p_id_cliente IN cliente.id_cliente%TYPE,
  p_lat        IN NUMBER,
  p_lng        IN NUMBER,
  p_precision  IN VARCHAR2
) AS
BEGIN
  UPDATE cliente
     SET lat = p_lat,
         lng = p_lng,
         geo_precision = p_precision,
         geo_at = SYSTIMESTAMP
   WHERE id_cliente = p_id_cliente;
END;
/

CREATE OR REPLACE PROCEDURE pr_export_clientes_geo(
  p_filename IN VARCHAR2 DEFAULT 'clientes_geo.csv'
) IS
  f UTL_FILE.FILE_TYPE;
BEGIN
  f := UTL_FILE.FOPEN('EXPORT_DIR', p_filename, 'w', 32767);
  UTL_FILE.PUT_LINE(f, 'rut,nombre,direccion,telefono,lat,lng');

  FOR r IN (
    SELECT c.rut, c.nombre, c.direccion, c.telefono, c.lat, c.lng
      FROM cliente c
  ) LOOP
    UTL_FILE.PUT_LINE(f,
      csv_str(r.rut) || ',' ||
      csv_str(r.nombre) || ',' ||
      csv_str(r.direccion) || ',' ||
      csv_str(r.telefono) || ',' ||
      csv_num(r.lat) || ',' ||
      csv_num(r.lng)
    );
  END LOOP;

  UTL_FILE.FCLOSE(f);
END;
/
