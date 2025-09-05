import oracledb from "oracledb";
import { withConn } from "../db.js";
import type { VentaBody, VentaResponse } from "../dto/ventas.dto.js";

async function detectBoletaOrigenColumn(conn: oracledb.Connection) {
  const q = `
    SELECT column_name AS COLUMN_NAME
    FROM user_tab_columns
    WHERE table_name = 'BOLETA_VENTA'
      AND column_name IN ('ID_UBICACION_ORIGEN','ID_UBICACION','ORIGEN_UBICACION')
    ORDER BY CASE column_name
               WHEN 'ID_UBICACION_ORIGEN' THEN 1
               WHEN 'ID_UBICACION'        THEN 2
               ELSE 3
             END
  `;
  const r = await conn.execute<{ COLUMN_NAME: string }>(q, [], {
    outFormat: oracledb.OUT_FORMAT_OBJECT,
  });
  return r.rows?.[0]?.COLUMN_NAME ?? "ORIGEN_UBICACION";
}

const SEL_PRECIO_INLINE = `
  SELECT d.precio_con_iva AS PRECIO
  FROM APP_PYME.LISTA_PRECIO_DET d
  JOIN APP_PYME.LISTA_PRECIO lp ON lp.id_lista = d.id_lista
  WHERE d.id_producto = :id_producto
    AND lp.id_lista = (
      SELECT valor_num
      FROM APP_PYME.PARAMETRO_SISTEMA
      WHERE codigo = 'PRECIO_LISTA_ACTIVA_ID'
    )
`;

async function getPrecioConIva(conn: oracledb.Connection, idProducto: number) {
  const r = await conn.execute<{ PRECIO: number }>(
    SEL_PRECIO_INLINE,
    { id_producto: idProducto },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  return r.rows?.[0]?.PRECIO != null ? Number(r.rows[0].PRECIO) : null;
}

async function preflightObjects(conn: oracledb.Connection) {
  const checks = [
    "SELECT 1 FROM APP_PYME.LISTA_PRECIO WHERE ROWNUM=1",
    "SELECT 1 FROM APP_PYME.LISTA_PRECIO_DET WHERE ROWNUM=1",
    "SELECT 1 FROM APP_PYME.PARAMETRO_SISTEMA WHERE codigo='PRECIO_LISTA_ACTIVA_ID' AND valor_num IS NOT NULL",
    "SELECT 1 FROM APP_PYME.BOLETA_VENTA WHERE ROWNUM=1",
    "SELECT 1 FROM APP_PYME.BOLETA_VENTA_DETALLE WHERE ROWNUM=1",
  ];
  for (const sql of checks) {
    await conn.execute(sql);
  }
}

export async function insertVenta(
  body: VentaBody,
  userId: number
): Promise<VentaResponse> {
  return withConn(async (conn) => {
    let step = "init";
    try {
      step = "resolve-origen";
      let origenUbicacion = body.origenUbicacion;
      if (!Number.isInteger(Number(origenUbicacion))) {
        const r = await conn.execute<{ ID: number }>(
          `SELECT id_ubicacion AS ID FROM APP_PYME.UBICACION WHERE nombre='LOCAL'`,
          [],
          { outFormat: oracledb.OUT_FORMAT_OBJECT }
        );
        origenUbicacion = r.rows?.[0]?.ID ?? 2;
      }
      origenUbicacion = Number(origenUbicacion);

      step = "detect-cols";
      const origenCol = await detectBoletaOrigenColumn(conn);
      const usuarioCol = "ID_USUARIO_VENDE" as const;

      step = "preflight";
      await preflightObjects(conn);

      step = "savepoint";
      await conn.execute(`SAVEPOINT sp_ini`);

      const outId = { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } as const;

      const cols = `numero, id_cliente, fecha, estado, neto, iva, total, ${origenCol}, ${usuarioCol}`;
      const vals = `:numero, :id_cliente, SYSTIMESTAMP, 'PAGADA', 0, 0, 0, :origen, :user_id`;

      const sqlInsCab = `
        INSERT INTO APP_PYME.BOLETA_VENTA (${cols})
        VALUES (${vals})
        RETURNING id_boleta INTO :id_boleta
      `;

      const rIns = await conn.execute<unknown>(sqlInsCab, {
        numero: body.numero,
        id_cliente: body.idCliente,
        origen: origenUbicacion,
        user_id: userId,
        id_boleta: outId,
      });
      const idBoleta: number = (rIns.outBinds as { id_boleta: number[] }).id_boleta[0];

      step = "insert-detalle";
      let detallesInsertados = 0;
      for (const it of body.items) {
        const precio = await getPrecioConIva(conn, it.idProducto);
        if (precio == null) {
          throw new Error(`No hay precio vigente para producto ${it.idProducto}`);
        }
        const rDet = await conn.execute(
          `INSERT INTO APP_PYME.BOLETA_VENTA_DETALLE (id_boleta, id_producto, cantidad, precio_unitario)
           VALUES (:id_boleta, :id_producto, :cantidad, :precio)`,
          {
            id_boleta: idBoleta,
            id_producto: it.idProducto,
            cantidad: it.cantidad,
            precio,
          }
        );
        if (rDet.rowsAffected) detallesInsertados += rDet.rowsAffected;
      }
      if (detallesInsertados === 0) {
        throw new Error("No se insertó ningún detalle");
      }

      step = "sum-totales";
      const rSum = await conn.execute<{ TOTAL: number }>(
        `SELECT SUM(cantidad * precio_unitario) AS TOTAL
           FROM APP_PYME.BOLETA_VENTA_DETALLE
          WHERE id_boleta = :id_boleta`,
        { id_boleta: idBoleta },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      const total = Number(rSum.rows?.[0]?.TOTAL ?? 0);
      const neto = Math.round(total / 1.19);
      const iva = total - neto;

      step = "update-cabecera";
      await conn.execute(
        `UPDATE APP_PYME.BOLETA_VENTA
            SET neto = :neto, iva = :iva, total = :total
          WHERE id_boleta = :id_boleta`,
        { neto, iva, total, id_boleta: idBoleta }
      );

      step = "pr_registrar_venta";
      await conn.execute(`BEGIN APP_PYME.pr_registrar_venta(:p_id); END;`, {
        p_id: idBoleta,
      });

      step = "commit";
      await conn.commit();

      return {
        ok: true,
        idBoleta,
        numero: body.numero,
        idCliente: body.idCliente,
        origenUbicacion,
        items: body.items,
        totales: { neto, iva, total },
      };
    } catch (e) {
      try {
        await conn.rollback();
      } catch {
        /* ignore */
      }
      throw new Error(`${step}: ${String((e as Error).message || e)}`);
    }
  });
}
