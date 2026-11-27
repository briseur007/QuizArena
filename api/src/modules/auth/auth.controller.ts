import type { Request, Response } from 'express';
import { currentUser } from '../../middlewares/auth.js';
import { loginBody, refreshBody, registerBody } from './auth.schemas.js';
import * as service from './auth.service.js';

export async function register(req: Request, res: Response) {
  res.status(201).json(await service.register(registerBody.parse(req.body)));
}

export async function login(req: Request, res: Response) {
  res.json(await service.login(loginBody.parse(req.body)));
}

export async function refresh(req: Request, res: Response) {
  res.json(await service.refresh(refreshBody.parse(req.body).refreshToken));
}

export async function logout(req: Request, res: Response) {
  await service.logout(refreshBody.parse(req.body).refreshToken);
  res.status(204).end();
}

export async function me(req: Request, res: Response) {
  res.json(await service.me(currentUser(req).id));
}
