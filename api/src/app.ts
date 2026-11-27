import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { env } from './config/env.js';
import { errorHandler, notFound } from './middlewares/error.js';

export function createApp() {
  const app = express();

  // A11 : middlewares de sécurité
  app.use(helmet());
  app.use(cors({ origin: env.CORS_ORIGIN }));
  app.use(express.json({ limit: '100kb' }));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  // TODO : monter les modules ici
  // app.use('/auth', authRoutes);
  // app.use('/courses', courseRoutes);
  // app.use('/quizzes', quizRoutes);
  // app.use('/attempts', attemptRoutes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
