import request from "supertest";
import { describe, it, expect, beforeEach, vi } from "vitest";
import app from "../src/app.js";
import * as authService from "../src/services/auth.service.js";
import * as usersRepo from "../src/repositories/users.repo.js";
import * as tokensRepo from "../src/repositories/tokens.repo.js";
import * as ventasService from "../src/services/ventas.service.js";

const ventaBody = {
  numero: "B-1",
  idCliente: 1,
  origenUbicacion: 2,
  items: [{ idProducto: 1, cantidad: 1 }],
};

const ventaResponse = {
  ok: true,
  idBoleta: 1,
  numero: "B-1",
  idCliente: 1,
  origenUbicacion: 2,
  items: [{ idProducto: 1, cantidad: 1 }],
  totales: { neto: 100, iva: 19, total: 119 },
};

describe("auth flow", () => {
  beforeEach(() => {
    usersRepo.clear();
    tokensRepo.clear();
    vi.restoreAllMocks();
  });

  it("login válido", async () => {
    await authService.register("a@a.com", "pass", "ventas");
    const res = await request(app)
      .post("/auth/login")
      .send({ email: "a@a.com", password: "pass" });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
  });

  it("login inválido", async () => {
    const res = await request(app)
      .post("/auth/login")
      .send({ email: "no@a.com", password: "bad" });
    expect(res.status).toBe(401);
  });

  it("refresh rota token", async () => {
    await authService.register("b@b.com", "pass", "ventas");
    const login = await request(app)
      .post("/auth/login")
      .send({ email: "b@b.com", password: "pass" });
    const oldRefresh = login.body.refreshToken;
    const refreshed = await request(app)
      .post("/auth/refresh")
      .send({ refreshToken: oldRefresh });
    expect(refreshed.status).toBe(200);
    expect(refreshed.body.refreshToken).not.toBe(oldRefresh);
    const reused = await request(app)
      .post("/auth/refresh")
      .send({ refreshToken: oldRefresh });
    expect(reused.status).toBe(401);
  });

  it("logout invalida refresh", async () => {
    await authService.register("c@c.com", "pass", "ventas");
    const login = await request(app)
      .post("/auth/login")
      .send({ email: "c@c.com", password: "pass" });
    const refresh = login.body.refreshToken;
    await request(app).post("/auth/logout").send({ refreshToken: refresh });
    const res = await request(app)
      .post("/auth/refresh")
      .send({ refreshToken: refresh });
    expect(res.status).toBe(401);
  });

  it("protección de rutas", async () => {
    await authService.register("consulta@d.com", "pass", "consulta");
    const loginConsulta = await request(app)
      .post("/auth/login")
      .send({ email: "consulta@d.com", password: "pass" });
    const tokenConsulta = loginConsulta.body.accessToken;

    const noToken = await request(app)
      .post("/api/ventas")
      .send(ventaBody);
    expect(noToken.status).toBe(401);

    const resConsulta = await request(app)
      .post("/api/ventas")
      .set("Authorization", `Bearer ${tokenConsulta}`)
      .send(ventaBody);
    expect(resConsulta.status).toBe(403);

    await authService.register("ventas@d.com", "pass", "ventas");
    const loginVentas = await request(app)
      .post("/auth/login")
      .send({ email: "ventas@d.com", password: "pass" });
    const tokenVentas = loginVentas.body.accessToken;
    vi.spyOn(ventasService, "createVenta").mockResolvedValue(ventaResponse);
    const ok = await request(app)
      .post("/api/ventas")
      .set("Authorization", `Bearer ${tokenVentas}`)
      .send(ventaBody);
    expect(ok.status).toBe(201);
  });
});
