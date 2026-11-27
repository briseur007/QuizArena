import type { NextFunction, Request, Response } from 'express';
import mongoose from 'mongoose';
import { z, ZodError } from 'zod';

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

// Raccourcis pour les erreurs les plus courantes.
export const badRequest = (message: string, code = 'BAD_REQUEST') => new AppError(400, code, message);
export const unauthorized = (message = 'Authentification requise', code = 'UNAUTHORIZED') =>
  new AppError(401, code, message);
export const forbidden = (message = 'Action non autorisée', code = 'FORBIDDEN') => new AppError(403, code, message);
export const notFound = (message = 'Ressource introuvable', code = 'NOT_FOUND') => new AppError(404, code, message);
export const conflict = (message: string, code = 'CONFLICT') => new AppError(409, code, message);
export const unprocessable = (message: string, details?: unknown, code = 'VALIDATION_ERROR') =>
  new AppError(422, code, message, details);

// Erreurs levées par express.json() (body-parser) : JSON malformé, corps trop gros, etc.
// Elles portent un `type` et un `status` 4xx ; sans ce mapping elles finiraient en 500.
const BODY_PARSER_ERRORS: Record<string, { status: number; code: string; message: string }> = {
  'entity.parse.failed': { status: 400, code: 'INVALID_JSON', message: 'Corps JSON invalide' },
  'entity.too.large': { status: 413, code: 'PAYLOAD_TOO_LARGE', message: 'Corps de requête trop volumineux' },
};

function bodyParserError(err: unknown) {
  if (typeof err !== 'object' || err === null || !('type' in err)) return undefined;
  return BODY_PARSER_ERRORS[String(err.type)];
}

/** Clé dupliquée MongoDB (index unique) : conflit métier. */
function isDuplicateKey(err: unknown): boolean {
  return typeof err === 'object' && err !== null && 'code' in err && err.code === 11000;
}

export function routeNotFound(_req: Request, _res: Response, next: NextFunction) {
  next(new AppError(404, 'NOT_FOUND', 'Route introuvable'));
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    return res.status(422).json({
      error: { code: 'VALIDATION_ERROR', message: 'Données invalides', details: z.flattenError(err).fieldErrors },
    });
  }
  if (err instanceof AppError) {
    return res.status(err.status).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
  }
  const parserError = bodyParserError(err);
  if (parserError) {
    return res.status(parserError.status).json({
      error: { code: parserError.code, message: parserError.message },
    });
  }
  if (err instanceof mongoose.Error.CastError) {
    return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ressource introuvable' } });
  }
  if (isDuplicateKey(err)) {
    return res.status(409).json({ error: { code: 'CONFLICT', message: 'Cet élément existe déjà' } });
  }
  console.error(err);
  return res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Erreur interne' } });
}
