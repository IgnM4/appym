import { z } from "zod";

const envSchema = z.object({
  PORT: z.coerce.number().int().optional(),
  API_PORT: z.coerce.number().int().optional(),
  ALLOW_START_WITHOUT_DB: z.string().optional().transform(v => v === "true").default("false"),
  DB_USER: z.string().optional(),
  DB_PASSWORD: z.string().optional(),
  DB_CONNECT: z.string().optional(),
  LOG_LEVEL: z.string().default("info"),
  ALLOWED_ORIGINS: z.string().default(""),
  TRUST_PROXY: z.string().optional().transform(v => v === "true").default("false"),
  JWT_SECRET: z.string(),
  JWT_EXPIRES_IN: z.string().default("15m"),
  REFRESH_EXPIRES_IN: z.string().default("7d"),
  API_KEY_SALT: z.string(),
  IDEMPOTENCY_TTL_SEC: z.coerce.number().int().positive().default(86_400),
});

const parsed = envSchema.parse(process.env);

const config = {
  port: parsed.API_PORT ?? parsed.PORT ?? 4000,
  allowStartWithoutDb: parsed.ALLOW_START_WITHOUT_DB,
  dbUser: parsed.DB_USER,
  dbPassword: parsed.DB_PASSWORD,
  dbConnect: parsed.DB_CONNECT,
  logLevel: parsed.LOG_LEVEL,
  allowedOrigins: parsed.ALLOWED_ORIGINS
    .split(",")
    .map(o => o.trim())
    .filter(o => o.length > 0),
  trustProxy: parsed.TRUST_PROXY,
  auth: {
    jwtSecret: parsed.JWT_SECRET,
    jwtExpiresIn: parsed.JWT_EXPIRES_IN,
    refreshExpiresIn: parsed.REFRESH_EXPIRES_IN,
    apiKeySalt: parsed.API_KEY_SALT,
  },
  limits: {
    idempotencyTtlSec: parsed.IDEMPOTENCY_TTL_SEC,
  },
};

export type Config = typeof config;
export default config;
