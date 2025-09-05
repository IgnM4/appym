import { withConn } from "../db.js";
import config from "../config.js";
import type { UserRole } from "./users.repo.js";

interface ApiKeyRecord {
  name: string;
  keyHash: string;
  role: UserRole;
}

const keys = new Map<string, ApiKeyRecord>();

function useDb(): boolean {
  return Boolean(config.dbConnect) && !config.allowStartWithoutDb;
}

export async function createKey(data: ApiKeyRecord): Promise<void> {
  if (!useDb()) {
    keys.set(data.keyHash, data);
    return;
  }
  await withConn(async (conn) => {
    await conn.execute(
      `INSERT INTO API_KEYS (NAME, KEY_HASH, ROLE) VALUES (:name,:keyHash,:role)`,
      data,
      { autoCommit: true }
    );
  });
}

export async function findByHash(keyHash: string): Promise<ApiKeyRecord | null> {
  if (!useDb()) {
    return keys.get(keyHash) ?? null;
  }
  return withConn(async (conn) => {
    const result = await conn.execute<ApiKeyRecord>(
      `SELECT NAME as "name", KEY_HASH as "keyHash", ROLE as "role" FROM API_KEYS WHERE KEY_HASH=:keyHash`,
      { keyHash }
    );
    return result.rows?.[0] ?? null;
  });
}

export async function revokeKey(keyHash: string): Promise<void> {
  if (!useDb()) {
    keys.delete(keyHash);
    return;
  }
  await withConn(async (conn) => {
    await conn.execute(
      `DELETE FROM API_KEYS WHERE KEY_HASH=:keyHash`,
      { keyHash },
      { autoCommit: true }
    );
  });
}

export function clear(): void {
  keys.clear();
}
