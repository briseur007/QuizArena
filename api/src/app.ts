import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { env } from './config/env.js';
import { errorHandler, routeNotFound } from './middlewares/error.js';
import { apiRoutes } from './routes.js';

export interface AppOptions {
  /** Requêtes /auth autorisées par IP et par fenêtre de 15 min (A11). */
  authRateLimit?: number;
}

export function createApp(options: AppOptions = {}) {
  const app = express();

  // Derrière un proxy (hébergeur), pour que le rate limiting voie l'IP réelle.
  app.set('trust proxy', env.TRUST_PROXY);
  app.disable('x-powered-by');

  // A11 : middlewares de sécurité
  app.use(helmet());
  app.use(cors({ origin: env.CORS_ORIGIN }));
  app.use(express.json({ limit: '100kb' }));

  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: options.authRateLimit ?? env.AUTH_RATE_LIMIT_MAX,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: (_req, res) =>
      res.status(429).json({
        error: { code: 'TOO_MANY_REQUESTS', message: 'Trop de tentatives, réessaie dans quelques minutes' },
      }),
  });

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.use(apiRoutes(authLimiter));

  app.use(routeNotFound);
  app.use(errorHandler);

  return app;
}
