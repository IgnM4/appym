import oracledb from "oracledb";
import { withConn } from "../db.js";
import config from "../config.js";

export type UserRole = "admin" | "ventas" | "consulta";
export interface User {
  id: string;
  email: string;
  passwordHash: string;
  role: UserRole;
}

const users = new Map<string, User>();
let seq = 1;

function useDb(): boolean {
  return Boolean(config.dbConnect) && !config.allowStartWithoutDb;
}

export async function findByEmail(email: string): Promise<User | null> {
  if (!useDb()) {
    for (const u of users.values()) {
      if (u.email === email) return u;
    }
    return null;
  }
  return withConn(async (conn) => {
    const result = await conn.execute<User>(
      `SELECT ID as "id", EMAIL as "email", PASSWORD_HASH as "passwordHash", ROLE as "role" FROM USERS WHERE EMAIL=:email`,
      { email }
    );
    return result.rows?.[0] ?? null;
  });
}

export async function createUser(data: {
  email: string;
  passwordHash: string;
  role: UserRole;
}): Promise<User> {
  if (!useDb()) {
    const id = String(seq++);
    const user: User = { id, ...data };
    users.set(id, user);
    return user;
  }
  return withConn(async (conn) => {
    const result = await conn.execute(
      `INSERT INTO USERS (EMAIL, PASSWORD_HASH, ROLE) VALUES (:email,:passwordHash,:role) RETURNING ID INTO :id`,
      { ...data, id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER } },
      { autoCommit: true }
    );
    const id = String((result.outBinds as { id: number[] }).id[0]);
    return { id, ...data };
  });
}

export async function findById(id: string): Promise<User | null> {
  if (!useDb()) {
    return users.get(id) ?? null;
  }
  return withConn(async (conn) => {
    const result = await conn.execute<User>(
      `SELECT ID as "id", EMAIL as "email", PASSWORD_HASH as "passwordHash", ROLE as "role" FROM USERS WHERE ID=:id`,
      { id }
    );
    return result.rows?.[0] ?? null;
  });
}

export function clear(): void {
  users.clear();
  seq = 1;
}
