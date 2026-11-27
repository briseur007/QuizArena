import type { NextFunction, Request, Response } from 'express';
import { z, ZodError } from 'zod';

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
      error: { code: 'VALIDATION_ERROR', message: 'Données invalides', details: z.flattenError(err).fieldErrors },
    });
  }
  const parserError = bodyParserError(err);
  if (parserError) {
    return res.status(parserError.status).json({
      error: { code: parserError.code, message: parserError.message },
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
