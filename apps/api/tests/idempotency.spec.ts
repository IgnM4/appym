import request from "supertest";
import { describe, it, expect, beforeEach, vi } from "vitest";
import app from "../src/app.js";
import * as authService from "../src/services/auth.service.js";
import * as usersRepo from "../src/repositories/users.repo.js";
import * as tokensRepo from "../src/repositories/tokens.repo.js";
import * as idempotencyRepo from "../src/repositories/idempotency.repo.js";
import * as ventasService from "../src/services/ventas.service.js";

const body = {
  numero: "B-1",
  idCliente: 1,
  origenUbicacion: 2,
  items: [{ idProducto: 1, cantidad: 1 }],
};

const response = {
  ok: true,
  idBoleta: 1,
  numero: "B-1",
  idCliente: 1,
  origenUbicacion: 2,
  items: [{ idProducto: 1, cantidad: 1 }],
  totales: { neto: 100, iva: 19, total: 119 },
};

describe("idempotency", () => {
  beforeEach(() => {
    usersRepo.clear();
    tokensRepo.clear();
    idempotencyRepo.clear();
    vi.restoreAllMocks();
  });

  it("reutiliza respuesta", async () => {
    await authService.register("v@v.com", "pass", "ventas");
    const login = await request(app)
      .post("/auth/login")
      .send({ email: "v@v.com", password: "pass" });
    const token = login.body.accessToken;
    vi.spyOn(ventasService, "createVenta").mockResolvedValue(response);
    const idemKey = "key-1";
    const first = await request(app)
      .post("/api/ventas")
      .set("Authorization", `Bearer ${token}`)
      .set("Idempotency-Key", idemKey)
      .send(body);
    expect(first.status).toBe(201);
    const second = await request(app)
      .post("/api/ventas")
      .set("Authorization", `Bearer ${token}`)
      .set("Idempotency-Key", idemKey)
      .send(body);
    expect(second.status).toBe(201);
    expect(second.body).toEqual(first.body);
    expect(ventasService.createVenta).toHaveBeenCalledTimes(1);
  });
});
