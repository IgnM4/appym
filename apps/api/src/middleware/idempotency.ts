import type { Request, Response, NextFunction } from "express";
import crypto from "node:crypto";
import * as repo from "../repositories/idempotency.repo.js";
import config from "../config.js";

export async function idempotency(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const key = req.header("Idempotency-Key");
  if (!key) return next();
  const body = req.body ? JSON.stringify(req.body) : "";
  const fingerprint = crypto
    .createHash("sha256")
    .update(`${req.method}:${req.originalUrl}:${body}`)
    .digest("hex");
  const existing = await repo.getOrSet(
    key,
    fingerprint,
    config.limits.idempotencyTtlSec
  );
  if (existing.reused) {
    const cached = existing.response as { status: number; body: unknown };
    res.status(cached.status).json(cached.body);
    return;
  }
  const originalJson = res.json.bind(res);
  res.json = (bodyData: unknown) => {
    void repo.getOrSet(key, fingerprint, config.limits.idempotencyTtlSec, {
      status: res.statusCode,
      body: bodyData,
    });
    return originalJson(bodyData);
  };
  next();
}
