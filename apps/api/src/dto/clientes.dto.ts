import { z } from "zod";
import type { Request } from "express";

export const clienteIdParamsSchema = z.object({
  id: z.coerce.number().int().positive(),
});
export type ClienteIdParams = z.infer<typeof clienteIdParamsSchema>;

export const clienteBodySchema = z.object({
  rut: z.string().min(1),
  nombre: z.string().min(1),
  direccion: z.string().optional(),
  telefono: z.string().optional(),
  email: z.string().email().optional(),
});
export type ClienteBody = z.infer<typeof clienteBodySchema>;

export interface ClienteResponse extends ClienteBody {
  id: number;
  createdAt?: string;
}

export function parseClienteIdFromParams(req: Request): number {
  return clienteIdParamsSchema.parse(req.params).id;
}

export function parseClienteBody(req: Request): ClienteBody {
  return clienteBodySchema.parse(req.body);
}
