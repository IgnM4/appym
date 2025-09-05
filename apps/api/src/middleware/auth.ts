import type { Request, Response, NextFunction } from "express";
import { jwtVerify } from "jose";
import config from "../config.js";

export async function bearerAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }
  const token = header.slice(7);
  try {
    const { payload } = await jwtVerify(
      token,
      new TextEncoder().encode(config.auth.jwtSecret)
    );
    req.user = {
      id: String(payload.sub),
      role: payload.role as "admin" | "ventas" | "consulta",
    };
    next();
  } catch {
    res.status(401).json({ error: "Unauthorized" });
  }
}

export function requireRole(
  ...roles: Array<"admin" | "ventas" | "consulta">
) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }
    if (!roles.includes(req.user.role)) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }
    next();
  };
}
