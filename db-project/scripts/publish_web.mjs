// scripts/publish_web.mjs (fragmento conceptual)
import { execSync } from "node:child_process";

const SQLCL_BIN = process.env.SQLCL_BIN; // ej: "C:\\oracle\\sqlcl\\bin\\sql"
const EXPORT_DIR = process.env.EXPORT_DIR || "web-app/public/data";

if (!SQLCL_BIN) {
  console.warn("SQLCL_BIN no definido. Corriendo en modo sin BD (solo copia de archivos).");
  // copia CSVs si ya existen...
  process.exit(0);
}

// Usa DB_URL/DB_USER/DB_PASS o bien los APP_DB_* si prefieres, pero sé consistente
const DB_URL = process.env.DB_URL;     // jdbc:oracle:thin:@//localhost:1521/XEPDB1
const DB_USER = process.env.DB_USER;
const DB_PASS = process.env.DB_PASS;

if (!DB_URL || !DB_USER || !DB_PASS) {
  console.error("Faltan DB_URL/DB_USER/DB_PASS en entorno.");
  process.exit(1);
}

// Ejecuta SQLcl / exporta y copia a EXPORT_DIR...
