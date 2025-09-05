import { withConn } from "../db.js";
import config from "../config.js";

interface RefreshToken {
  userId: string;
  tokenHash: string;
  expiresAt: Date;
}

const tokens = new Map<string, RefreshToken>();

function useDb(): boolean {
  return Boolean(config.dbConnect) && !config.allowStartWithoutDb;
}

export async function storeRefresh(data: RefreshToken): Promise<void> {
  if (!useDb()) {
    tokens.set(data.tokenHash, data);
    return;
  }
  await withConn(async (conn) => {
    await conn.execute(
      `INSERT INTO REFRESH_TOKENS (USER_ID, TOKEN_HASH, EXPIRES_AT) VALUES (:userId,:tokenHash,:expiresAt)`,
      data,
      { autoCommit: true }
    );
  });
}

export async function revokeRefresh(tokenHash: string): Promise<void> {
  if (!useDb()) {
    tokens.delete(tokenHash);
    return;
  }
  await withConn(async (conn) => {
    await conn.execute(
      `DELETE FROM REFRESH_TOKENS WHERE TOKEN_HASH=:tokenHash`,
      { tokenHash },
      { autoCommit: true }
    );
  });
}

export async function isValidRefresh(tokenHash: string): Promise<{ userId: string } | null> {
  if (!useDb()) {
    const t = tokens.get(tokenHash);
    if (!t) return null;
    if (t.expiresAt.getTime() < Date.now()) {
      tokens.delete(tokenHash);
      return null;
    }
    return { userId: t.userId };
  }
  return withConn(async (conn) => {
    const result = await conn.execute<{ userId: string }>(
      `SELECT USER_ID as "userId", EXPIRES_AT as "expiresAt" FROM REFRESH_TOKENS WHERE TOKEN_HASH=:tokenHash`,
      { tokenHash }
    );
    const row = result.rows?.[0];
    if (!row) return null;
    const expiresAt = row as unknown as { userId: string; expiresAt: Date };
    if (expiresAt.expiresAt.getTime() < Date.now()) {
      await revokeRefresh(tokenHash);
      return null;
    }
    return { userId: expiresAt.userId };
  });
}

export function clear(): void {
  tokens.clear();
}
