import type { Request, Response } from 'express';
import { currentUser } from '../../middlewares/auth.js';
import { idParams } from '../../utils/validation.js';
import { leaderboardQuery, saveAnswerBody, submitBody } from './attempts.schemas.js';
import * as service from './attempts.service.js';

/** POST /quizzes/:id/attempts — 201 si créée, 200 si reprise. */
export async function start(req: Request, res: Response) {
  const { created, attempt } = await service.start(currentUser(req), idParams.parse(req.params).id);
  res.status(created ? 201 : 200).json(attempt);
}

export async function saveAnswer(req: Request, res: Response) {
  const { id } = idParams.parse(req.params);
  const { questionId, optionIndex } = saveAnswerBody.parse(req.body);
  await service.saveAnswer(currentUser(req), id, questionId, optionIndex);
  res.status(204).end();
}

export async function submit(req: Request, res: Response) {
  const { id } = idParams.parse(req.params);
  res.json(await service.submit(currentUser(req), id, submitBody.parse(req.body ?? {})));
}

export async function result(req: Request, res: Response) {
  res.json(await service.result(currentUser(req), idParams.parse(req.params).id));
}

export async function latest(req: Request, res: Response) {
  res.json(await service.latest(currentUser(req)));
}

export async function quizLeaderboard(req: Request, res: Response) {
  const { id } = idParams.parse(req.params);
  res.json(await service.quizLeaderboard(currentUser(req), id, leaderboardQuery.parse(req.query)));
}

export async function courseLeaderboard(req: Request, res: Response) {
  const { id } = idParams.parse(req.params);
  res.json(await service.courseLeaderboard(currentUser(req), id, leaderboardQuery.parse(req.query)));
}
