import { z } from "zod";
import type { Request } from "express";

export const loginBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});
export type LoginBody = z.infer<typeof loginBodySchema>;
export function parseLoginBody(req: Request): LoginBody {
  return loginBodySchema.parse(req.body);
}

export const refreshBodySchema = z.object({
  refreshToken: z.string().min(1),
});
export type RefreshBody = z.infer<typeof refreshBodySchema>;
export function parseRefreshBody(req: Request): RefreshBody {
  return refreshBodySchema.parse(req.body);
}

export const apiKeyBodySchema = z.object({
  name: z.string().min(1),
  role: z.enum(["admin", "ventas", "consulta"]),
});
export type ApiKeyBody = z.infer<typeof apiKeyBodySchema>;
export function parseApiKeyBody(req: Request): ApiKeyBody {
  return apiKeyBodySchema.parse(req.body);
}
