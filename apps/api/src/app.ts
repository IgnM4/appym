import express, { type Request, type Response, type NextFunction } from "express";
import "dotenv/config";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import pinoHttp from "pino-http";
import crypto from "node:crypto";
import path from "node:path";
import swaggerUi from "swagger-ui-express";

import ventas from "./routes/ventas.js";
import clientes from "./routes/clientes.js";
import authRoutes from "./routes/auth.js";
import { bearerAuth, requireRole } from "./middleware/auth.js";
import { apiKeyAuth } from "./middleware/apiKey.js";
import { initPool, isDbHealthy, closePool } from "./db.js";
import errorHandler from "./middleware/error.js";
import logger from "./logger.js";
import config from "./config.js";

type ResWithTime = Response & { responseTime?: number };

const app = express();

if (config.trustProxy) {
  app.set("trust proxy", 1);
}

app.use(
  pinoHttp({
    logger,
    genReqId(req, res) {
      const existing = req.headers["x-request-id"];
      const id = typeof existing === "string" ? existing : crypto.randomUUID();
      res.setHeader("X-Request-Id", id);
      res.locals.requestId = id;
      return id;
    },
    customReceivedMessage: (req) => `--> ${req.method} ${req.url}`,
    customSuccessMessage: (req, res: ResWithTime) =>
      `<-- ${req.method} ${req.url} ${res.statusCode} ${
        res.getHeader("content-length") ?? 0
      }b ${res.responseTime ?? 0}ms`,
    customErrorMessage: (req, res: ResWithTime, err: Error) =>
      `<-- ${req.method} ${req.url} ${res.statusCode} ${
        res.responseTime ?? 0
      }ms ${err.message}`,
    redact: {
      paths: ["req.headers.authorization", "req.body.password"],
      censor: "***",
    },
  })
);

app.use(helmet());

const limiter = rateLimit({
  windowMs: 60_000,
  limit: 100,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.path.startsWith("/health") || req.path.startsWith("/ready"),
});
app.use(limiter);

const allowedOrigins = config.allowedOrigins;
const corsMw = cors({ origin: allowedOrigins });
app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
    return corsMw(req, res, next);
  }
  res.status(403).send("CORS Forbidden");
});

app.use(express.json());

function authOrApiKey(req: Request, res: Response, next: NextFunction): void {
  if (req.headers["x-api-key"]) {
    void apiKeyAuth(req, res, next);
    return;
  }
  void bearerAuth(req, res, next);
}

app.get("/health", (_req: Request, res: Response) => {
  res.json({ db: isDbHealthy() ? "up" : "down" });
});

app.get("/ready", (_req: Request, res: Response) => {
  const healthy = isDbHealthy();
  res.status(healthy ? 200 : 503).json({ db: healthy ? "up" : "down" });
});

app.use("/auth", authRoutes);
app.use(
  "/api/ventas",
  authOrApiKey,
  requireRole("admin", "ventas"),
  ventas
);
app.use(
  "/api/clientes",
  authOrApiKey,
  requireRole("admin", "ventas", "consulta"),
  clientes
);

const openApiPath = path.join(__dirname, "openapi.json");
app.get("/openapi.json", (_req, res) => {
  res.sendFile(openApiPath);
});
app.use("/docs", swaggerUi.serve, swaggerUi.setup(undefined, { swaggerUrl: "/openapi.json" }));

const PORT = config.port;
const allowStartWithoutDb = config.allowStartWithoutDb;

if (!process.env.VITEST) {
  logger.info("Iniciando API...");
  initPool()
    .catch((err: unknown) => {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error({ err }, "No se pudo conectar a la base de datos: %s", msg);
      if (!allowStartWithoutDb) {
        process.exit(1);
      }
      logger.warn(
        "Continuando sin conexión a la BD por ALLOW_START_WITHOUT_DB=true"
      );
    })
    .finally(() => {
      const server = app.listen(PORT, () => {
        logger.info(`API en http://localhost:${PORT}`);
      });

      server.on("error", (err: unknown) => {
        const e = err as NodeJS.ErrnoException;
        if (e && e.code === "EADDRINUSE") {
          logger.error(`Puerto ${PORT} en uso.`);
        } else {
          logger.error(e);
        }
        process.exit(1);
      });
    });
}

app.use((_req: Request, res: Response) =>
  res.status(404).json({ error: "Not found" })
);
app.use(errorHandler);

async function shutdown(signal: NodeJS.Signals): Promise<void> {
  logger.info({ signal }, "Cerrando...");
  try {
    await closePool();
  } catch (e) {
    logger.error({ err: e }, "Error al cerrar pool");
    process.exit(1);
    return;
  }
  process.exit(0);
}

process.on("SIGINT", () => {
  void shutdown("SIGINT");
});
process.on("SIGTERM", () => {
  void shutdown("SIGTERM");
});

process.on("unhandledRejection", (reason) => {
  logger.error({ err: reason }, "Unhandled rejection");
});
process.on("uncaughtException", (err) => {
  logger.error({ err }, "Uncaught exception");
});

export default app;
