import { type RequestHandler, Router } from 'express';
import { requireAuth, requireRole } from './middlewares/auth.js';
import * as attempts from './modules/attempts/attempts.controller.js';
import { authRoutes } from './modules/auth/auth.routes.js';
import * as courses from './modules/courses/courses.controller.js';
import * as quizzes from './modules/quizzes/quizzes.controller.js';

/**
 * Table de routage de l'API. Chaque route déclare qui peut l'appeler :
 * `requireAuth` (connecté) puis éventuellement `requireRole` (A7, rôle).
 * Le contrôle objet par objet (« ce cours est-il le mien ? ») est fait
 * dans les services.
 */
export function apiRoutes(authLimiter: RequestHandler) {
  const router = Router();
  const teacher = [requireAuth, requireRole('teacher')];
  const student = [requireAuth, requireRole('student')];

  router.use('/auth', authRoutes(authLimiter));

  // Cours
  router.get('/courses', requireAuth, courses.list);
  router.post('/courses', ...teacher, courses.create);
  router.post('/courses/join', ...student, courses.join);
  router.get('/courses/:id/quizzes', requireAuth, quizzes.listForCourse);
  router.post('/courses/:id/quizzes', ...teacher, quizzes.createForCourse);
  router.get('/courses/:id/leaderboard', requireAuth, attempts.courseLeaderboard);

  // Quiz
  router.get('/quizzes', requireAuth, quizzes.listMine);
  router.get('/quizzes/:id', ...teacher, quizzes.getOne);
  router.patch('/quizzes/:id', ...teacher, quizzes.update);
  router.post('/quizzes/:id/publish', ...teacher, quizzes.publish);
  router.post('/quizzes/:id/close', ...teacher, quizzes.close);
  router.get('/quizzes/:id/report', ...teacher, quizzes.report);
  router.get('/quizzes/:id/leaderboard', requireAuth, attempts.quizLeaderboard);
  router.post('/quizzes/:id/attempts', ...student, attempts.start);

  // Tentatives (« me/latest » avant « :id »)
  router.get('/attempts/me/latest', ...student, attempts.latest);
  router.put('/attempts/:id/answers', ...student, attempts.saveAnswer);
  router.post('/attempts/:id/submit', ...student, attempts.submit);
  router.get('/attempts/:id', requireAuth, attempts.result);

  return router;
}
