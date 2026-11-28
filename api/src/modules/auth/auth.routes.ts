import { type RequestHandler, Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import * as controller from './auth.controller.js';

/** [authLimiter] : A11, limite les essais de mots de passe par IP. */
export function authRoutes(authLimiter: RequestHandler) {
  const router = Router();
  router.post('/register', authLimiter, controller.register);
  router.post('/login', authLimiter, controller.login);
  router.post('/refresh', authLimiter, controller.refresh);
  router.post('/logout', controller.logout);
  router.get('/me', requireAuth, controller.me);
  router.patch('/me', requireAuth, controller.updateMe);
  // Limité comme la connexion : on y vérifie un mot de passe (force brute).
  router.patch('/me/password', authLimiter, requireAuth, controller.changePassword);
  return router;
}
