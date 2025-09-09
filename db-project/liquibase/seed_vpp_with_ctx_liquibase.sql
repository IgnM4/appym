DECLARE
  v_boleta   NUMBER;
  v_p1       NUMBER;
  v_p2       NUMBER;
  v_numero   NUMBER;
  v_user_id  CONSTANT NUMBER := 1;

  v_owner_det VARCHAR2(30);
  v_owner_bol VARCHAR2(30);
  v_owner_prod VARCHAR2(30);

  -- Devuelve el owner real del objeto
  FUNCTION resolve_owner(p_tab VARCHAR2) RETURN VARCHAR2 IS
    v_o VARCHAR2(30);
  BEGIN
    SELECT owner INTO v_o
      FROM all_objects
     WHERE object_name = UPPER(p_tab)
       AND object_type IN ('TABLE','VIEW')
       AND ROWNUM = 1;
    RETURN v_o;
  END;

  -- ¿Existe columna en ALL_TAB_COLS para owner/tab?
  FUNCTION has_col(p_owner VARCHAR2, p_tab VARCHAR2, p_col VARCHAR2) RETURN BOOLEAN IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
      FROM all_tab_cols
     WHERE owner = UPPER(p_owner)
       AND table_name = UPPER(p_tab)
       AND column_name = UPPER(p_col);
    RETURN v_cnt > 0;
  END;

  -- Siguiente ID para detalle, respetando el nombre de columna que exista
  FUNCTION next_det_id(p_owner VARCHAR2) RETURN NUMBER IS
    v_id  NUMBER;
    v_col VARCHAR2(30);
    v_sql VARCHAR2(500);
  BEGIN
    IF has_col(p_owner,'BOLETA_VENTA_DETALLE','ID_DETALLE') THEN
      v_col := 'ID_DETALLE';
    ELSIF has_col(p_owner,'BOLETA_VENTA_DETALLE','ID_BOLETA_DETALLE') THEN
      v_col := 'ID_BOLETA_DETALLE';
    ELSE
      RETURN NULL;
    END IF;

    v_sql := 'SELECT NVL(MAX('||v_col||'),0)+1 FROM '||p_owner||'.BOLETA_VENTA_DETALLE';
    EXECUTE IMMEDIATE v_sql INTO v_id;
    RETURN v_id;
  END;

  PROCEDURE ensure_prod(
    p_sku VARCHAR2, p_nombre VARCHAR2, p_formato VARCHAR2, p_um VARCHAR2, p_costo NUMBER, p_precio NUMBER
  ) IS
    v_cnt NUMBER;
  BEGIN
    EXECUTE IMMEDIATE
      'SELECT COUNT(*) FROM '||v_owner_prod||'.producto WHERE sku = :1'
      INTO v_cnt USING p_sku;

    IF v_cnt = 0 THEN
      EXECUTE IMMEDIATE '
        INSERT INTO '||v_owner_prod||'.producto
          (sku, nombre, formato, unidad_medida, costo, precio, activo, fecha_creacion, creado_por)
        VALUES (:1, :2, :3, :4, :5, :6, ''S'', SYSTIMESTAMP, USER)'
      USING p_sku, p_nombre, p_formato, p_um, p_costo, p_precio;
    END IF;
  END;

  PROCEDURE insert_det(p_owner VARCHAR2, p_prod NUMBER, p_qty NUMBER, p_price NUMBER, p_desc NUMBER, p_line NUMBER) IS
    v_id      NUMBER := next_det_id(p_owner);
    v_cols    VARCHAR2(4000) := 'id_boleta,id_producto,cantidad,precio_unitario,descuento';
    v_vals    VARCHAR2(4000) := ':boleta,:prod,:qty,:price,:desc';
    v_idcol   VARCHAR2(30);
    v_linecol VARCHAR2(30);
    v_sql     VARCHAR2(4000);
  BEGIN
    IF has_col(p_owner,'BOLETA_VENTA_DETALLE','ID_DETALLE') THEN
      v_idcol := 'ID_DETALLE';
    ELSIF has_col(p_owner,'BOLETA_VENTA_DETALLE','ID_BOLETA_DETALLE') THEN
      v_idcol := 'ID_BOLETA_DETALLE';
    END IF;

    IF v_idcol IS NOT NULL THEN
      v_cols := v_idcol||','||v_cols;
      v_vals := ':id,'||v_vals;
    END IF;

    IF has_col(p_owner,'BOLETA_VENTA_DETALLE','N_LINEA') THEN
      v_linecol := 'N_LINEA';
    ELSIF has_col(p_owner,'BOLETA_VENTA_DETALLE','NUMERO_LINEA') THEN
      v_linecol := 'NUMERO_LINEA';
    END IF;

    IF v_linecol IS NOT NULL THEN
      v_cols := v_cols||','||v_linecol;
      v_vals := v_vals||',:linea';
    END IF;

    v_sql := 'INSERT INTO '||p_owner||'.BOLETA_VENTA_DETALLE ('||v_cols||') VALUES ('||v_vals||')';

    IF v_idcol IS NOT NULL AND v_linecol IS NOT NULL THEN
      EXECUTE IMMEDIATE v_sql USING
        IN v_id, IN v_boleta, IN p_prod, IN p_qty, IN p_price, IN p_desc, IN p_line;
    ELSIF v_idcol IS NOT NULL THEN
      EXECUTE IMMEDIATE v_sql USING
        IN v_id, IN v_boleta, IN p_prod, IN p_qty, IN p_price, IN p_desc;
    ELSIF v_linecol IS NOT NULL THEN
      EXECUTE IMMEDIATE v_sql USING
        IN v_boleta, IN p_prod, IN p_qty, IN p_price, IN p_desc, IN p_line;
    ELSE
      EXECUTE IMMEDIATE v_sql USING
        IN v_boleta, IN p_prod, IN p_qty, IN p_price, IN p_desc;
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN NULL;
  END;

BEGIN
  -- Resolver owners (asumimos que todo vive en el mismo esquema que detalle; ajusta si no)
  v_owner_det  := resolve_owner('BOLETA_VENTA_DETALLE');
  v_owner_bol  := resolve_owner('BOLETA_VENTA');
  v_owner_prod := resolve_owner('PRODUCTO');

  -- Productos base
  ensure_prod('SKU-11KG','Gas 11 kg','11KG','UN',8000,12000);
  ensure_prod('SKU-5KG' ,'Gas 5 kg' ,'5KG' ,'UN',4000, 6000);

  -- Crear boleta
  EXECUTE IMMEDIATE 'SELECT '||v_owner_bol||'.SEQ_BOLETA_NUMERO.NEXTVAL FROM dual' INTO v_numero;

  EXECUTE IMMEDIATE '
    INSERT INTO '||v_owner_bol||'.boleta_venta
      (numero, fecha, id_cliente, id_usuario_vende, neto, iva, total, metodo_pago, estado)
    VALUES (:1, SYSDATE, NULL, :2, :3, :4, :5, ''EFECTIVO'', ''PAGADA'')
    RETURNING id_boleta INTO :6'
    USING IN v_numero, IN v_user_id, IN 18000, IN 3420, IN 21420, OUT v_boleta;

  EXECUTE IMMEDIATE 'SELECT id_producto FROM '||v_owner_prod||'.producto WHERE sku = ''SKU-11KG''' INTO v_p1;
  EXECUTE IMMEDIATE 'SELECT id_producto FROM '||v_owner_prod||'.producto WHERE sku = ''SKU-5KG'''  INTO v_p2;

  insert_det(v_owner_det, v_p1, 1, 12000, 0, 1);
  insert_det(v_owner_det, v_p2, 1,  6000, 0, 2);

  -- Refresh MV si existe
  BEGIN
    EXECUTE IMMEDIATE 'BEGIN DBMS_MVIEW.REFRESH('''||v_owner_bol||'.MV_VENTAS_POR_PRODUCTO'',''C''); END;';
  EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/
