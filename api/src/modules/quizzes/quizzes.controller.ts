import type { Request, Response } from 'express';
import { currentUser } from '../../middlewares/auth.js';
import { idParams } from '../../utils/validation.js';
import { listQuizzesQuery, quizDraftBody } from './quizzes.schemas.js';
import * as service from './quizzes.service.js';

export async function listForCourse(req: Request, res: Response) {
  const { id } = idParams.parse(req.params);
  res.json(await service.listCourseQuizzes(currentUser(req), id, listQuizzesQuery.parse(req.query)));
}

export async function createForCourse(req: Request, res: Response) {
  const { id } = idParams.parse(req.params);
  res.status(201).json(await service.create(currentUser(req), id, quizDraftBody.parse(req.body)));
}

export async function listMine(req: Request, res: Response) {
  res.json(await service.listMyQuizzes(currentUser(req), listQuizzesQuery.parse(req.query)));
}

export async function getOne(req: Request, res: Response) {
  res.json(await service.getFull(currentUser(req), idParams.parse(req.params).id));
}

export async function update(req: Request, res: Response) {
  const { id } = idParams.parse(req.params);
  res.json(await service.update(currentUser(req), id, quizDraftBody.parse(req.body)));
}

export async function publish(req: Request, res: Response) {
  res.json(await service.publish(currentUser(req), idParams.parse(req.params).id));
}

export async function close(req: Request, res: Response) {
  res.json(await service.close(currentUser(req), idParams.parse(req.params).id));
}

export async function report(req: Request, res: Response) {
  res.json(await service.report(currentUser(req), idParams.parse(req.params).id));
}
