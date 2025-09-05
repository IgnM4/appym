import type { Request, Response, NextFunction } from "express";
import * as service from "../services/apiKey.service.js";

export async function apiKeyAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const key = req.headers["x-api-key"];
  if (typeof key !== "string") {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }
  const role = await service.getRole(key);
  if (!role) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }
  req.user = { id: "api-key", role };
  next();
}
