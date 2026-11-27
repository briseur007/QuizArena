import 'dotenv/config';
import { z } from 'zod';

// A3 : configuration validée au démarrage. L'API refuse de démarrer si une variable manque.
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  MONGODB_URI: z.string().min(1),
  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET doit faire au moins 32 caractères'),
  ACCESS_TOKEN_TTL: z.string().default('15m'),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(30),
  CORS_ORIGIN: z.string().default('*'),
  // Derrière le proxy de l'hébergeur (Render, Railway…), nombre de proxys à faire
  // confiance pour que le rate limiting voie la vraie IP du client.
  TRUST_PROXY: z.coerce.number().int().min(0).default(0),
  // A11 : tentatives autorisées sur /auth par IP et par fenêtre de 15 minutes.
  AUTH_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(20),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Configuration invalide :', z.flattenError(parsed.error).fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
