whenever sqlerror exit 1
set define off
INSERT INTO CLIENTES (RUT,NOMBRE,DIRECCION,TELEFONO,EMAIL) VALUES ('76.543.210-9','Gas Los Álamos','Av. Central 123','+56 9 1234 5678','contacto@losalamos.cl');
INSERT INTO CLIENTES (RUT,NOMBRE,DIRECCION,TELEFONO,EMAIL) VALUES ('11.111.111-1','Cliente Demo 1','Calle 1 #111','+56 2 2222 2222','demo1@empresa.com');
INSERT INTO CLIENTES (RUT,NOMBRE,DIRECCION,TELEFONO,EMAIL) VALUES ('22.222.222-2','Cliente Demo 2','Calle 2 #222','+56 2 3333 3333','demo2@empresa.com');
prompt 002_seed.sql DONE