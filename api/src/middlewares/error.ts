import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';

// A5 : un seul format d'erreur pour toute l'API
// { error: { code, message, details? } }
export class AppError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details?: unknown,
  ) {
    super(message);
  }
}

export function notFound(_req: Request, _res: Response, next: NextFunction) {
  next(new AppError(404, 'NOT_FOUND', 'Route introuvable'));
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    return res.status(422).json({
      error: { code: 'VALIDATION_ERROR', message: 'Données invalides', details: err.flatten().fieldErrors },
    });
  }
  if (err instanceof AppError) {
    return res.status(err.status).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
  }
  console.error(err);
  return res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Erreur interne' } });
}
