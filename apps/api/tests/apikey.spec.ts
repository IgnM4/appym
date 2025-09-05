import request from "supertest";
import { describe, it, expect, beforeEach, vi } from "vitest";
import app from "../src/app.js";
import * as authService from "../src/services/auth.service.js";
import * as usersRepo from "../src/repositories/users.repo.js";
import * as tokensRepo from "../src/repositories/tokens.repo.js";
import * as apiKeysRepo from "../src/repositories/apiKeys.repo.js";
import * as clientesService from "../src/services/clientes.service.js";

describe("api keys", () => {
  beforeEach(() => {
    usersRepo.clear();
    tokensRepo.clear();
    apiKeysRepo.clear();
    vi.restoreAllMocks();
  });

  it("crea y usa API key", async () => {
    await authService.register("admin@test.com", "pass", "admin");
    const login = await request(app)
      .post("/auth/login")
      .send({ email: "admin@test.com", password: "pass" });
    const created = await request(app)
      .post("/auth/apikey")
      .set("Authorization", `Bearer ${login.body.accessToken}`)
      .send({ name: "int", role: "ventas" });
    expect(created.status).toBe(201);
    const apiKey = created.body.apiKey as string;
    vi.spyOn(clientesService, "listClientes").mockResolvedValue([]);
    const res = await request(app)
      .get("/api/clientes")
      .set("x-api-key", apiKey);
    expect(res.status).toBe(200);
  });
});
