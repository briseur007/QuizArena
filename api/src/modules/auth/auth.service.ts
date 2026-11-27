import argon2 from 'argon2';
import { Types } from 'mongoose';
import type { z } from 'zod';
import type { Role } from '../../middlewares/auth.js';
import { conflict, unauthorized } from '../../middlewares/error.js';
import { Attempt } from '../attempts/attempt.model.js';
import type { loginBody, registerBody } from './auth.schemas.js';
import { Session } from './session.model.js';
import {
  formatRefreshToken,
  hashSecret,
  newRefreshSecret,
  parseRefreshToken,
  refreshExpiry,
  sameHash,
  signAccessToken,
} from './tokens.js';
import { User } from './user.model.js';

// A6 : Argon2id (paramètres par défaut de la bibliothèque, recommandés par l'OWASP).
const hashPassword = (password: string) => argon2.hash(password, { type: argon2.argon2id });

// Empreinte factice : on vérifie un mot de passe même si l'e-mail est inconnu,
// pour que le temps de réponse ne révèle pas quels comptes existent.
let dummyHash: Promise<string> | undefined;
const getDummyHash = () => (dummyHash ??= hashPassword('mot-de-passe-factice'));

export interface UserDto {
  id: string;
  name: string;
  email: string;
  role: Role;
  level: number;
}

interface UserLike {
  _id: Types.ObjectId;
  name: string;
  email: string;
  role: string;
}

/** Niveau affiché dans l'app (« Niveau 4 ») : +1 tous les 3 quiz remis. */
async function levelOf(userId: string, role: string): Promise<number> {
  if (role !== 'student') return 1;
  const submitted = await Attempt.countDocuments({ studentId: userId, status: 'submitted' });
  return 1 + Math.floor(submitted / 3);
}

export async function toUserDto(user: UserLike): Promise<UserDto> {
  const id = user._id.toString();
  return { id, name: user.name, email: user.email, role: user.role as Role, level: await levelOf(id, user.role) };
}

async function openSession(user: UserLike) {
  const secret = newRefreshSecret();
  const session = await Session.create({
    userId: user._id,
    tokenHash: hashSecret(secret),
    expiresAt: refreshExpiry(),
  });
  const sessionId = session._id.toString();
  return {
    user: await toUserDto(user),
    accessToken: signAccessToken(user._id.toString(), user.role as Role, sessionId),
    refreshToken: formatRefreshToken(sessionId, secret),
  };
}

export async function register(input: z.infer<typeof registerBody>) {
  if (await User.exists({ email: input.email })) {
    throw conflict('Un compte existe déjà avec cette adresse', 'EMAIL_TAKEN');
  }
  const user = await User.create({
    name: input.name,
    email: input.email,
    role: input.role,
    passwordHash: await hashPassword(input.password),
  });
  return openSession(user);
}

export async function login(input: z.infer<typeof loginBody>) {
  const user = await User.findOne({ email: input.email }).select('+passwordHash');
  const ok = await argon2.verify(user?.passwordHash ?? (await getDummyHash()), input.password);
  if (!user || !ok) throw unauthorized('E-mail ou mot de passe incorrect', 'INVALID_CREDENTIALS');
  return openSession(user);
}

/**
 * A6 : rotation. Chaque refresh remplace le secret ; l'ancien refresh token
 * devient inutilisable. Si un ancien token est rejoué (vol probable), la
 * session entière est révoquée.
 */
export async function refresh(refreshToken: string) {
  const parsed = parseRefreshToken(refreshToken);
  if (!parsed || !Types.ObjectId.isValid(parsed.sessionId)) throw unauthorized('Session invalide', 'REFRESH_INVALID');

  const session = await Session.findById(parsed.sessionId);
  if (!session || session.expiresAt < new Date()) throw unauthorized('Session expirée', 'REFRESH_INVALID');

  const presentedHash = hashSecret(parsed.secret);
  if (!sameHash(presentedHash, session.tokenHash)) {
    await session.deleteOne();
    throw unauthorized('Session révoquée', 'REFRESH_REUSED');
  }

  // Mise à jour conditionnelle : si deux refresh arrivent en même temps avec le
  // même token, un seul gagne ; l'autre reçoit 401.
  const secret = newRefreshSecret();
  const rotated = await Session.findOneAndUpdate(
    { _id: session._id, tokenHash: session.tokenHash },
    { tokenHash: hashSecret(secret), expiresAt: refreshExpiry() },
    { returnDocument: 'after' },
  );
  if (!rotated) throw unauthorized('Session déjà renouvelée', 'REFRESH_INVALID');

  const user = await User.findById(session.userId);
  if (!user) throw unauthorized('Compte introuvable', 'REFRESH_INVALID');

  const sessionId = session._id.toString();
  return {
    accessToken: signAccessToken(user._id.toString(), user.role as Role, sessionId),
    refreshToken: formatRefreshToken(sessionId, secret),
  };
}

/** Déconnexion : supprime la session ; idempotent (204 même si déjà révoquée). */
export async function logout(refreshToken: string) {
  const parsed = parseRefreshToken(refreshToken);
  if (!parsed || !Types.ObjectId.isValid(parsed.sessionId)) return;
  await Session.deleteOne({ _id: parsed.sessionId, tokenHash: hashSecret(parsed.secret) });
}

export async function me(userId: string) {
  const user = await User.findById(userId);
  if (!user) throw unauthorized('Compte introuvable');
  return toUserDto(user);
}
