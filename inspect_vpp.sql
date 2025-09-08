SET PAGESIZE 200 LINESIZE 200
COLUMN table_name FORMAT A30
COLUMN column_name FORMAT A30
COLUMN referenced_name FORMAT A30

PROMPT == Tablas existentes ==
SELECT table_name 
FROM user_tables
WHERE table_name IN ('PRODUCTO','VENTA','VENTA_ITEM','BOLETA_VENTA','BOLETA_ITEM')
ORDER BY 1;

PROMPT == Columnas en VENTA_ITEM y BOLETA_ITEM (si existen) ==
SELECT table_name, column_name, data_type
FROM user_tab_columns
WHERE table_name IN ('VENTA_ITEM','BOLETA_ITEM')
ORDER BY table_name, column_id;

PROMPT == Materialized views ==
SELECT object_name 
FROM user_objects 
WHERE object_type='MATERIALIZED VIEW'
ORDER BY 1;

PROMPT == Dependencias de MV_VENTAS_POR_PRODUCTO ==
SELECT name, type, referenced_name, referenced_type
FROM user_dependencies
WHERE name = 'MV_VENTAS_POR_PRODUCTO'
ORDER BY referenced_type, referenced_name;
