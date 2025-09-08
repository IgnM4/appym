SET SERVEROUTPUT ON
-- Intenta usar el package; si no existe el método, crea un body mínimo que lo provea
DECLARE
  tried BOOLEAN := FALSE;
BEGIN
  BEGIN
    PKG_APP_CTX.SET_ID_USUARIO(1);            -- ajusta el ID que quieras
    DBMS_OUTPUT.PUT_LINE('Contexto seteado via PKG_APP_CTX.SET_ID_USUARIO(1)');
    tried := TRUE;
  EXCEPTION WHEN OTHERS THEN NULL; END;

  IF NOT tried THEN
    DBMS_OUTPUT.PUT_LINE('Creando cuerpo mínimo de PKG_APP_CTX con SET_ID_USUARIO...');
    EXECUTE IMMEDIATE q'[
      CREATE OR REPLACE PACKAGE BODY PKG_APP_CTX AS
        PROCEDURE SET_ID_USUARIO(p_id NUMBER) IS
        BEGIN
          DBMS_SESSION.SET_CONTEXT('APP_CTX','ID_USUARIO', p_id);
        END;
      END PKG_APP_CTX;
    ]';
    PKG_APP_CTX.SET_ID_USUARIO(1);
    DBMS_OUTPUT.PUT_LINE('Contexto seteado tras crear body mínimo.');
  END IF;
END;
/
-- Verifica que quedó seteado
SELECT SYS_CONTEXT('APP_CTX','ID_USUARIO') AS ID_USUARIO FROM dual;
/
