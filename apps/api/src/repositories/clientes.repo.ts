import oracledb from "oracledb";
import { withConn } from "../db.js";
import type { ClienteBody, ClienteResponse } from "../dto/clientes.dto.js";

export async function list(): Promise<ClienteResponse[]> {
  return withConn(async (conn) => {
    const result = await conn.execute<ClienteResponse>(
      `SELECT
         ID         as "id",
         RUT        as "rut",
         NOMBRE     as "nombre",
         DIRECCION  as "direccion",
         TELEFONO   as "telefono",
         EMAIL      as "email",
         CREATED_AT as "createdAt"
       FROM CLIENTES
       ORDER BY ID DESC
       FETCH FIRST 100 ROWS ONLY`
    );
    return result.rows ?? [];
  });
}

export async function findById(id: number): Promise<ClienteResponse | null> {
  return withConn(async (conn) => {
    const result = await conn.execute<ClienteResponse>(
      `SELECT
         ID         as "id",
         RUT        as "rut",
         NOMBRE     as "nombre",
         DIRECCION  as "direccion",
         TELEFONO   as "telefono",
         EMAIL      as "email",
         CREATED_AT as "createdAt"
       FROM CLIENTES
       WHERE ID = :id`,
      { id }
    );
    return result.rows?.[0] ?? null;
  });
}

export async function insert(data: ClienteBody): Promise<ClienteResponse> {
  return withConn(async (conn) => {
    const result = await conn.execute(
      `INSERT INTO CLIENTES (RUT, NOMBRE, DIRECCION, TELEFONO, EMAIL)
       VALUES (:rut, :nombre, :direccion, :telefono, :email)
       RETURNING ID INTO :id`,
      {
        ...data,
        id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      },
      { autoCommit: true }
    );
    const id = (result.outBinds as { id: number[] }).id[0];
    return { id, ...data };
  });
}

export async function update(
  id: number,
  data: ClienteBody
): Promise<ClienteResponse | null> {
  return withConn(async (conn) => {
    const result = await conn.execute(
      `UPDATE CLIENTES
         SET RUT=:rut, NOMBRE=:nombre, DIRECCION=:direccion, TELEFONO=:telefono, EMAIL=:email
       WHERE ID=:id`,
      { id, ...data },
      { autoCommit: true }
    );
    if ((result.rowsAffected ?? 0) === 0) return null;
    return { id, ...data };
  });
}

export async function remove(id: number): Promise<boolean> {
  return withConn(async (conn) => {
    const result = await conn.execute(
      `DELETE FROM CLIENTES WHERE ID=:id`,
      { id },
      { autoCommit: true }
    );
    return (result.rowsAffected ?? 0) > 0;
  });
}
