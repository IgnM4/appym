import express from "express";
import { parseVentaBody } from "../dto/ventas.dto.js";
import * as service from "../services/ventas.service.js";
import { idempotency } from "../middleware/idempotency.js";

const router = express.Router();

router.post(
  "/",
  idempotency,
  async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    try {
      const body = parseVentaBody(req);
      const userId = Number(req.user?.id);
      const venta = await service.createVenta(body, userId);
      res.status(201).json(venta);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
