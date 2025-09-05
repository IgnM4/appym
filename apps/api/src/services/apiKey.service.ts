import crypto from "node:crypto";
import config from "../config.js";
import * as repo from "../repositories/apiKeys.repo.js";
import type { UserRole } from "../repositories/users.repo.js";

function hash(apiKey: string): string {
  return crypto
    .createHash("sha256")
    .update(config.auth.apiKeySalt + apiKey)
    .digest("hex");
}

export async function createKey(
  name: string,
  role: UserRole
): Promise<{ apiKey: string }> {
  const apiKey = `api_${crypto.randomBytes(16).toString("hex")}`;
  const keyHash = hash(apiKey);
  await repo.createKey({ name, keyHash, role });
  return { apiKey };
}

export async function getRole(apiKey: string): Promise<UserRole | null> {
  const keyHash = hash(apiKey);
  const record = await repo.findByHash(keyHash);
  return record?.role ?? null;
}

export async function revoke(apiKey: string): Promise<void> {
  const keyHash = hash(apiKey);
  await repo.revokeKey(keyHash);
}
