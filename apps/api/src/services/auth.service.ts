import crypto from "node:crypto";
import { SignJWT } from "jose";
import { hashSync, compareSync } from "bcryptjs";

import config from "../config.js";
import * as usersRepo from "../repositories/users.repo.js";
import * as tokensRepo from "../repositories/tokens.repo.js";
import type { UserRole, User } from "../repositories/users.repo.js";

function parseDuration(str: string): number {
  const match = /^([0-9]+)(ms|s|m|h|d)$/.exec(str);
  if (!match) throw new Error("Invalid duration");
  const value = Number(match[1]);
  const unit = match[2];
  switch (unit) {
    case "ms":
      return value;
    case "s":
      return value * 1000;
    case "m":
      return value * 60_000;
    case "h":
      return value * 3_600_000;
    case "d":
      return value * 86_400_000;
    default:
      throw new Error("Invalid duration");
  }
}

function hash(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

export async function register(
  email: string,
  password: string,
  role: UserRole
): Promise<User> {
  const passwordHash = hashSync(password, 10);
  return usersRepo.createUser({ email, passwordHash, role });
}

export async function login(email: string, password: string): Promise<{ accessToken: string; refreshToken: string } | null> {
  const user = await usersRepo.findByEmail(email);
  if (!user) return null;
  if (!compareSync(password, user.passwordHash)) return null;
  const accessToken = await new SignJWT({ role: user.role })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(user.id)
    .setExpirationTime(config.auth.jwtExpiresIn)
    .sign(new TextEncoder().encode(config.auth.jwtSecret));
  const refreshToken = crypto.randomUUID();
  const refreshHash = hash(refreshToken);
  const expiresAt = new Date(Date.now() + parseDuration(config.auth.refreshExpiresIn));
  await tokensRepo.storeRefresh({ userId: user.id, tokenHash: refreshHash, expiresAt });
  return { accessToken, refreshToken };
}

export async function refresh(
  refreshToken: string
): Promise<{ accessToken: string; refreshToken: string } | null> {
  const hashToken = hash(refreshToken);
  const data = await tokensRepo.isValidRefresh(hashToken);
  if (!data) return null;
  await tokensRepo.revokeRefresh(hashToken);
  const user = await usersRepo.findById(data.userId);
  if (!user) return null;
  const accessToken = await new SignJWT({ role: user.role })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(user.id)
    .setExpirationTime(config.auth.jwtExpiresIn)
    .sign(new TextEncoder().encode(config.auth.jwtSecret));
  const newRefresh = crypto.randomUUID();
  const newHash = hash(newRefresh);
  const expiresAt = new Date(Date.now() + parseDuration(config.auth.refreshExpiresIn));
  await tokensRepo.storeRefresh({ userId: user.id, tokenHash: newHash, expiresAt });
  return { accessToken, refreshToken: newRefresh };
}

export async function logout(refreshToken: string): Promise<void> {
  const hashToken = hash(refreshToken);
  await tokensRepo.revokeRefresh(hashToken);
}
