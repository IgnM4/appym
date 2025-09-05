import { withConn } from "../db.js";
import config from "../config.js";

interface Entry {
  fingerprint: string;
  response?: unknown;
  expiresAt: number;
}

const store = new Map<string, Entry>();

function useDb(): boolean {
  return Boolean(config.dbConnect) && !config.allowStartWithoutDb;
}

export async function getOrSet(
  key: string,
  fingerprint: string,
  ttlSec: number,
  response?: unknown
): Promise<{ reused: boolean; response?: unknown }> {
  if (!useDb()) {
    const now = Date.now();
    const existing = store.get(key);
    if (
      existing &&
      existing.expiresAt > now &&
      existing.fingerprint === fingerprint &&
      existing.response !== undefined
    ) {
      return { reused: true, response: existing.response };
    }
    if (response !== undefined) {
      store.set(key, { fingerprint, response, expiresAt: now + ttlSec * 1000 });
    } else if (!existing) {
      store.set(key, { fingerprint, expiresAt: now + ttlSec * 1000 });
    }
    return { reused: false };
  }
  return withConn(async (conn) => {
    const result = await conn.execute<{ fingerprint: string; response: unknown; expiresAt: Date }>(
      `SELECT FINGERPRINT as "fingerprint", RESPONSE as "response", EXPIRES_AT as "expiresAt" FROM IDEMPOTENCY WHERE KEY=:key`,
      { key }
    );
    const row = result.rows?.[0];
    const now = Date.now();
    if (row && row.expiresAt.getTime() > now && row.fingerprint === fingerprint) {
      return { reused: true, response: row.response };
    }
    if (response !== undefined) {
      await conn.execute(
        `MERGE INTO IDEMPOTENCY t USING (SELECT :key as KEY FROM dual) s ON (t.KEY=s.KEY)
        WHEN MATCHED THEN UPDATE SET FINGERPRINT=:fingerprint, RESPONSE=:response, EXPIRES_AT=:expiresAt
        WHEN NOT MATCHED THEN INSERT (KEY,FINGERPRINT,RESPONSE,EXPIRES_AT) VALUES (:key,:fingerprint,:response,:expiresAt)`,
        {
          key,
          fingerprint,
          response: JSON.stringify(response),
          expiresAt: new Date(now + ttlSec * 1000),
        },
        { autoCommit: true }
      );
    } else {
      await conn.execute(
        `INSERT INTO IDEMPOTENCY (KEY,FINGERPRINT,EXPIRES_AT) VALUES (:key,:fingerprint,:expiresAt)`,
        { key, fingerprint, expiresAt: new Date(now + ttlSec * 1000) },
        { autoCommit: true }
      );
    }
    return { reused: false };
  });
}

export function clear(): void {
  store.clear();
}
