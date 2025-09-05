-- ===== Drop seguro de los triggers fila-a-fila actuales =====
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_fc_det_recalc'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_bol_det_recalc'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ===== Compound trigger para FACTURA_COMPRA_DETALLE (recalcular totales) =====
CREATE OR REPLACE TRIGGER trg_fc_det_recalc
FOR INSERT OR UPDATE OR DELETE ON factura_compra_detalle
COMPOUND TRIGGER
  TYPE t_set IS TABLE OF BOOLEAN INDEX BY NUMBER;
  g_ids t_set;

  PROCEDURE mark(p NUMBER) IS
  BEGIN
    IF p IS NOT NULL THEN
      g_ids(p) := TRUE; -- set-like
    END IF;
  END;
  
  AFTER EACH ROW IS
  BEGIN
    mark(:NEW.id_factura_compra);
    mark(:OLD.id_factura_compra);
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v NUMBER;
  BEGIN
    v := g_ids.FIRST;
    WHILE v IS NOT NULL LOOP
      pr_recalc_fc(v);
      v := g_ids.NEXT(v);
    END LOOP;
  END AFTER STATEMENT;
END;
/
SHOW ERRORS TRIGGER trg_fc_det_recalc

-- ===== Compound trigger para BOLETA_VENTA_DETALLE (recalcular totales) =====
CREATE OR REPLACE TRIGGER trg_bol_det_recalc
FOR INSERT OR UPDATE OR DELETE ON boleta_venta_detalle
COMPOUND TRIGGER
  TYPE t_set IS TABLE OF BOOLEAN INDEX BY NUMBER;
  g_ids t_set;

  PROCEDURE mark(p NUMBER) IS
  BEGIN
    IF p IS NOT NULL THEN
      g_ids(p) := TRUE; -- set-like
    END IF;
  END;

  AFTER EACH ROW IS
  BEGIN
    mark(:NEW.id_boleta);
    mark(:OLD.id_boleta);
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v NUMBER;
  BEGIN
    v := g_ids.FIRST;
    WHILE v IS NOT NULL LOOP
      pr_recalc_bol(v);
      v := g_ids.NEXT(v);
    END LOOP;
  END AFTER STATEMENT;
END;
/
SHOW ERRORS TRIGGER trg_bol_det_recalc
