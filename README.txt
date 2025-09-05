# Arranque rápido (Windows)

1) Requisitos:
   - Docker Desktop
   - Node.js 18+ y npm
   - Contenedor Oracle con docker compose (archivo en APP\docker-compose.yml)

2) Levantar base de datos:
   - Abrir PowerShell en APP:
     docker compose up -d
   - Ver logs:
     docker logs -f app-oracle-xe-1
   - Probar login (opcional):
     docker exec -it app-oracle-xe-1 bash -lc "sqlplus -L APP_PYME/app_pyme_pass@localhost:1521/XEPDB1"

3) Iniciar API (dev):
   - PowerShell:
     cd APP\server
     set PORT=4000
     set DB_USER=APP_PYME
     set DB_PASSWORD=app_pyme_pass
     set DB_CONNECT=localhost:1521/XEPDB1
     npm run dev
   - Abrir en: http://localhost:4000

4) Script de un clic:
   - Doble clic: APP\start-app.bat

5) Troubleshooting rápido:
   - ORA-28000 (cuenta bloqueada):
     docker exec -it app-oracle-xe-1 bash
     sqlplus / as sysdba
     ALTER SESSION SET CONTAINER = XEPDB1;
     ALTER USER APP_PYME IDENTIFIED BY "app_pyme_pass" ACCOUNT UNLOCK;

   - ORA-01017 (usuario/clave):
     Verificar variables de entorno (DB_USER, DB_PASSWORD, DB_CONNECT).
     Comprobar login:
     docker exec -it app-oracle-xe-1 bash -lc "sqlplus -L APP_PYME/app_pyme_pass@localhost:1521/XEPDB1"

   - Puerto incorrecto:
     La app usa 4000 por defecto; ajustar PORT o el código:
       const port = Number(process.env.PORT ?? process.env.API_PORT ?? 4000);
