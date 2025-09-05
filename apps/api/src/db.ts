// server/src/db.ts
import oracledb from "oracledb";

// Cache de sentencias y formato por nombre de columna
oracledb.stmtCacheSize = 50;
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;

let pool: oracledb.Pool | undefined;
let dbHealthy = false;

function getConnectString(): string {
  // Soportamos los 3 nombres; prioridad a DB_CONNECT (el que venías usando)
  return (
    process.env.DB_CONNECT ||
    process.env.DB_CONNECT_STRING ||
    process.env.DB_URL ||
    "localhost:1521/XEPDB1"
  );
}

function getUser(): string {
  // Por defecto apuntamos a tu esquema real
  return process.env.DB_USER || "APP_PYME";
}
function getPassword(): string {
  return process.env.DB_PASSWORD || "app_pyme_pass";
}

async function createPoolWithRetry(maxRetries = 5, baseDelayMs = 500): Promise<void> {
  const user = getUser();
  const connectString = getConnectString();
  const poolMin = Number(process.env.DB_POOL_MIN ?? 0);
  const poolMax = Number(process.env.DB_POOL_MAX ?? 5);
  const poolIncrement = Number(process.env.DB_POOL_INC ?? 1);

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log("DB init", {
        attempt: `${attempt}/${maxRetries}`,
        user,
        connectString,
        poolMin,
        poolMax,
        poolIncrement,
      });

      pool = await oracledb.createPool({
        user,
        password: getPassword(),
        connectString,
        poolMin,
        poolMax,
        poolIncrement,
        stmtCacheSize: 50,
      });

      // Smoke test real: si esto falla, no marcamos healthy
      const cn = await pool.getConnection();
      await cn.execute("SELECT 1 FROM dual");
      await cn.close();

      dbHealthy = true;
      console.log("Conexión a Oracle establecida y verificada ✅");
      return;
    } catch (err: unknown) {
      dbHealthy = false;
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`Error conectando a Oracle (intento ${attempt}/${maxRetries}):`, msg);

      // Si es claramente credencial/DSN, no sigas reintentando a ciegas
      if (/ORA-01017|ORA-12154|ORA-12514|ORA-12541|ORA-12545/.test(msg)) {
        console.error("Verifica DB_USER/DB_PASSWORD/DB_CONNECT. Abortando reintentos.");
        throw err;
      }

      if (attempt === maxRetries) throw err;

      const delay = baseDelayMs * 2 ** (attempt - 1);
      await new Promise((r) => setTimeout(r, delay));
    }
  }
}

export async function initPool(): Promise<oracledb.Pool> {
  if (!pool) {
    await createPoolWithRetry();
  }
  // pool no debería ser undefined aquí, pero por tipo:
  if (!pool) throw new Error("Pool no inicializado tras reintentos");
  return pool;
}

export function isDbHealthy(): boolean {
  return dbHealthy;
}

export async function getPool(): Promise<oracledb.Pool> {
  if (!pool) {
    await initPool();
  }
  if (!pool) {
    throw new Error("Pool no inicializado");
  }
  return pool;
}

// Helper para ejecutar con conexión y cerrarla siempre
export async function withConn<T>(fn: (cn: oracledb.Connection) => Promise<T>): Promise<T> {
  const p = await getPool();
  const cn = await p.getConnection();
  try {
    return await fn(cn);
  } finally {
    try {
      await cn.close();
    } catch {
      /* ignore close errors */
    }
  }
}

// Cierre ordenado (por ejemplo al recibir SIGTERM en producción)
export async function closePool(): Promise<void> {
  if (pool) {
    console.log("Cerrando pool de Oracle...");
    try {
      await pool.close(5); // espera hasta 5s a que terminen
    } finally {
      pool = undefined;
      dbHealthy = false;
      console.log("Pool cerrado.");
    }
  }
}
