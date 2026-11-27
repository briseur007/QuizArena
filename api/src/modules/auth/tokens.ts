import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';
import jwt, { type SignOptions } from 'jsonwebtoken';
import { env } from '../../config/env.js';
import type { Role } from '../../middlewares/auth.js';

/** Jeton d'accès court (15 min par défaut), signé HS256. */
export function signAccessToken(userId: string, role: Role, sessionId: string): string {
  return jwt.sign({ role, sid: sessionId }, env.JWT_ACCESS_SECRET, {
    subject: userId,
    algorithm: 'HS256',
    expiresIn: env.ACCESS_TOKEN_TTL as SignOptions['expiresIn'],
  });
}

/**
 * Refresh token opaque : « <idSession>.<secret aléatoire> ».
 * L'identifiant permet de retrouver la session ; le secret est vérifié par empreinte.
 */
export function newRefreshSecret(): string {
  return randomBytes(32).toString('base64url');
}

export function hashSecret(secret: string): string {
  return createHash('sha256').update(secret).digest('hex');
}

export function formatRefreshToken(sessionId: string, secret: string): string {
  return `${sessionId}.${secret}`;
}

export function parseRefreshToken(token: string): { sessionId: string; secret: string } | null {
  const [sessionId, secret, ...rest] = token.split('.');
  if (!sessionId || !secret || rest.length > 0) return null;
  return { sessionId, secret };
}

/** Comparaison à temps constant (évite les attaques temporelles). */
export function sameHash(a: string, b: string): boolean {
  const ba = Buffer.from(a, 'hex');
  const bb = Buffer.from(b, 'hex');
  return ba.length === bb.length && timingSafeEqual(ba, bb);
}

export function refreshExpiry(): Date {
  return new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000);
}
