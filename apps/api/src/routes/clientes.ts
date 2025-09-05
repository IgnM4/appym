import express from "express";
import {
  parseClienteBody,
  parseClienteIdFromParams,
} from "../dto/clientes.dto.js";
import * as service from "../services/clientes.service.js";

const router = express.Router();

router.get(
  "/",
  async (
    _req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    try {
      const clientes = await service.listClientes();
      res.json(clientes);
    } catch (err) {
      next(err);
    }
  }
);

router.get(
  "/:id",
  async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    try {
      const id = parseClienteIdFromParams(req);
      const cliente = await service.getCliente(id);
      if (!cliente) return res.status(404).json({ error: "No encontrado" });
      res.json(cliente);
    } catch (err) {
      next(err);
    }
  }
);

router.post(
  "/",
  async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    try {
      const body = parseClienteBody(req);
      const cliente = await service.createCliente(body);
      res.status(201).json(cliente);
    } catch (err) {
      next(err);
    }
  }
);

router.put(
  "/:id",
  async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    try {
      const id = parseClienteIdFromParams(req);
      const body = parseClienteBody(req);
      const cliente = await service.updateCliente(id, body);
      if (!cliente) return res.status(404).json({ error: "No encontrado" });
      res.json(cliente);
    } catch (err) {
      next(err);
    }
  }
);

router.delete(
  "/:id",
  async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    try {
      const id = parseClienteIdFromParams(req);
      const removed = await service.deleteCliente(id);
      if (!removed) return res.status(404).json({ error: "No encontrado" });
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
);

export default router;
