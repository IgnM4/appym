-- 023 - Pendientes de devolución de vacío (secuencia + trigger, en un bloque)

DECLARE
  c_e_obj_exists CONSTANT PLS_INTEGER := -955;   -- nombre ya existe
  c_e_fk_exists  CONSTANT PLS_INTEGER := -2261;  -- FK ya existe
  c_e_fk_dup     CONSTANT PLS_INTEGER := -2275;  -- FK duplicada / ya creada
BEGIN
  -- Tabla
  BEGIN
    EXECUTE IMMEDIATE q'[
      CREATE TABLE pendiente_vacio (
        id_pend       NUMBER PRIMARY KEY,
        id_cliente    NUMBER NOT NULL,
        id_producto   NUMBER NOT NULL,
        cantidad      NUMBER NOT NULL,
        fecha_entrega DATE,
        resuelto      CHAR(1) DEFAULT 'N' NOT NULL CHECK (resuelto IN ('S','N')),
        observacion   VARCHAR2(200)
      )
    ]';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != c_e_obj_exists THEN RAISE; END IF;
  END;

  -- Secuencia
  BEGIN
    EXECUTE IMMEDIATE q'[CREATE SEQUENCE seq_pendiente_vacio START WITH 1 INCREMENT BY 1 NOCACHE]';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != c_e_obj_exists THEN RAISE; END IF;
  END;

  -- Trigger autoincremental
  BEGIN
    EXECUTE IMMEDIATE q'[
      CREATE OR REPLACE TRIGGER bi_pendiente_vacio
      BEFORE INSERT ON pendiente_vacio
      FOR EACH ROW
      WHEN (NEW.id_pend IS NULL)
      BEGIN
        :NEW.id_pend := seq_pendiente_vacio.NEXTVAL;
      END;
    ]';
  END;

  -- FKs (tolerantes a re-ejecución)
  BEGIN
    EXECUTE IMMEDIATE
      'ALTER TABLE pendiente_vacio ADD CONSTRAINT fk_pend_vacio__cliente
         FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE NOT IN (c_e_fk_exists, c_e_fk_dup) THEN RAISE; END IF;
  END;

  BEGIN
    EXECUTE IMMEDIATE
      'ALTER TABLE pendiente_vacio ADD CONSTRAINT fk_pend_vacio__producto
         FOREIGN KEY (id_producto) REFERENCES producto(id_producto)';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE NOT IN (c_e_fk_exists, c_e_fk_dup) THEN RAISE; END IF;
  END;

  -- Vista
  EXECUTE IMMEDIATE q'[
    CREATE OR REPLACE VIEW v_pendiente_vacio_activo AS
    SELECT p.* FROM pendiente_vacio p WHERE p.resuelto = 'N'
  ]';
END;
