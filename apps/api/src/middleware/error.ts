import type { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";

export default function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  if (err instanceof ZodError) {
    res.status(400).json({ error: "Validation error", issues: err.issues });
    return;
  }
  const msg = err instanceof Error ? err.message : "Internal error";
  res.status(500).json({ error: msg });
}
