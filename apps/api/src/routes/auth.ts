import { Router } from "express";
import {
  parseLoginBody,
  parseRefreshBody,
  parseApiKeyBody,
} from "../dto/auth.dto.js";
import * as authService from "../services/auth.service.js";
import * as apiKeyService from "../services/apiKey.service.js";
import { bearerAuth, requireRole } from "../middleware/auth.js";

const router = Router();

router.post("/login", async (req, res, next) => {
  try {
    const body = parseLoginBody(req);
    const tokens = await authService.login(body.email, body.password);
    if (!tokens) return res.status(401).json({ error: "Unauthorized" });
    res.json(tokens);
  } catch (err) {
    next(err);
  }
});

router.post("/refresh", async (req, res, next) => {
  try {
    const body = parseRefreshBody(req);
    const tokens = await authService.refresh(body.refreshToken);
    if (!tokens) return res.status(401).json({ error: "Unauthorized" });
    res.json(tokens);
  } catch (err) {
    next(err);
  }
});

router.post("/logout", async (req, res, next) => {
  try {
    const body = parseRefreshBody(req);
    await authService.logout(body.refreshToken);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.post(
  "/apikey",
  bearerAuth,
  requireRole("admin"),
  async (req, res, next) => {
    try {
      const body = parseApiKeyBody(req);
      const key = await apiKeyService.createKey(body.name, body.role);
      res.status(201).json(key);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
