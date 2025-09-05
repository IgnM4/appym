import { z } from "zod";
import type { Request } from "express";

const ventaItemSchema = z.object({
  idProducto: z.coerce.number().int().positive(),
  cantidad: z.coerce.number().int().positive(),
});

export const ventaBodySchema = z.object({
  numero: z.string().min(1),
  idCliente: z.coerce.number().int().positive(),
  origenUbicacion: z.coerce.number().int().positive().optional(),
  items: z.array(ventaItemSchema).min(1),
});
export type VentaBody = z.infer<typeof ventaBodySchema>;

export interface VentaResponse {
  ok: true;
  idBoleta: number;
  numero: string;
  idCliente: number;
  origenUbicacion: number;
  items: Array<{ idProducto: number; cantidad: number }>;
  totales: { neto: number; iva: number; total: number };
}

export function parseVentaBody(req: Request): VentaBody {
  return ventaBodySchema.parse(req.body);
}
