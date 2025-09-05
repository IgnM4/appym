import type { VentaBody, VentaResponse } from "../dto/ventas.dto.js";
import * as repo from "../repositories/ventas.repo.js";

export async function createVenta(
  body: VentaBody,
  userId: number
): Promise<VentaResponse> {
  return repo.insertVenta(body, userId);
}
