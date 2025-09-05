-- Trigger: si no viene el id_usuario_vende, lo toma del contexto
CREATE OR REPLACE TRIGGER trg_boleta_set_usuario
BEFORE INSERT ON boleta_venta
FOR EACH ROW
DECLARE
  v_ctx VARCHAR2(30);
BEGIN
  IF :NEW.id_usuario_vende IS NULL THEN
    v_ctx := SYS_CONTEXT('APP_PYME_CTX','ID_USUARIO');
    IF v_ctx IS NULL THEN
      RAISE_APPLICATION_ERROR(-20050, 'ID_USUARIO no seteado en contexto de sesión');
    END IF;
    :NEW.id_usuario_vende := TO_NUMBER(v_ctx);
  END IF;
END;
/
