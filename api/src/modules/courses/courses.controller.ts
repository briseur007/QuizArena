import type { Request, Response } from 'express';
import { currentUser } from '../../middlewares/auth.js';
import { createCourseBody, joinCourseBody, listCoursesQuery } from './courses.schemas.js';
import * as service from './courses.service.js';

export async function list(req: Request, res: Response) {
  res.json(await service.listMine(currentUser(req), listCoursesQuery.parse(req.query)));
}

export async function create(req: Request, res: Response) {
  res.status(201).json(await service.create(currentUser(req), createCourseBody.parse(req.body)));
}

export async function join(req: Request, res: Response) {
  res.json(await service.join(currentUser(req), joinCourseBody.parse(req.body).code));
}
