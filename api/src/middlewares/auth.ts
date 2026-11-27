import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { forbidden, unauthorized } from './error.js';

export type Role = 'student' | 'teacher';

export interface AuthUser {
  id: string;
  role: Role;
  sessionId: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

interface AccessPayload {
  sub: string;
  role: Role;
  sid: string;
}

/** Vérifie le jeton d'accès (`Authorization: Bearer …`) et renseigne `req.user`. */
export function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return next(unauthorized());

  try {
    const payload = jwt.verify(header.slice(7), env.JWT_ACCESS_SECRET, { algorithms: ['HS256'] }) as AccessPayload;
    req.user = { id: payload.sub, role: payload.role, sessionId: payload.sid };
    next();
  } catch {
    next(unauthorized('Jeton invalide ou expiré', 'TOKEN_INVALID'));
  }
}

/** A7 : contrôle de rôle. À placer après `requireAuth`. */
export function requireRole(role: Role) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (req.user?.role !== role) {
      return next(forbidden(role === 'teacher' ? 'Réservé aux enseignants' : 'Réservé aux étudiants'));
    }
    next();
  };
}

/** Utilisateur connecté (garanti par `requireAuth`). */
export function currentUser(req: Request): AuthUser {
  if (!req.user) throw unauthorized();
  return req.user;
}
