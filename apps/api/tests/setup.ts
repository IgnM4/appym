import { vi } from "vitest";

vi.mock("oracledb", () => {
  const execute = vi.fn().mockResolvedValue({ rows: [], outBinds: {} });
  const connection = { execute, commit: vi.fn(), rollback: vi.fn(), close: vi.fn() };
  const pool = { getConnection: vi.fn().mockResolvedValue(connection), close: vi.fn() };
  return {
    default: {
      createPool: vi.fn().mockResolvedValue(pool),
      getPool: vi.fn(() => pool),
      OUT_FORMAT_OBJECT: 1,
      BIND_OUT: 0,
      NUMBER: 0,
    },
  };
});

process.env.JWT_SECRET = "test-secret";
process.env.JWT_EXPIRES_IN = "15m";
process.env.REFRESH_EXPIRES_IN = "7d";
process.env.API_KEY_SALT = "salt";
process.env.IDEMPOTENCY_TTL_SEC = "86400";
process.env.ALLOW_START_WITHOUT_DB = "true";
