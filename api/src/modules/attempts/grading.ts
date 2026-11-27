import type { Types } from 'mongoose';
import { Question } from '../quizzes/question.model.js';
import { Attempt, type AttemptDoc } from './attempt.model.js';

/**
 * Délai de grâce après l'heure de fin : absorbe la latence réseau d'une
 * réponse envoyée à la dernière seconde. Au-delà, plus rien n'est accepté.
 */
export const GRACE_MS = 3_000;

export const isExpired = (attempt: { expiresAt: Date }, now = new Date()) =>
  now.getTime() > attempt.expiresAt.getTime() + GRACE_MS;

interface AnswerLike {
  questionId: Types.ObjectId | string;
  optionIndex: number;
  answeredAt: Date;
}

/** Dernière réponse donnée à chaque question, avant la fin du temps. */
export function lastAnswers(answers: AnswerLike[], expiresAt: Date): Map<string, number> {
  const deadline = expiresAt.getTime() + GRACE_MS;
  const result = new Map<string, number>();
  for (const a of [...answers].sort((x, y) => x.answeredAt.getTime() - y.answeredAt.getTime())) {
    if (a.answeredAt.getTime() <= deadline) result.set(a.questionId.toString(), a.optionIndex);
  }
  return result;
}

/**
 * Correction côté serveur (règle T17) et clôture de la tentative.
 *
 * Mise à jour conditionnelle sur `status: 'in_progress'` : si deux remises
 * arrivent en même temps, une seule est prise en compte.
 * Renvoie la tentative corrigée, ou `null` si elle était déjà remise.
 */
export async function finalize(attempt: AttemptDoc, now = new Date()): Promise<AttemptDoc | null> {
  const questions = await Question.find({ quizId: attempt.quizId }).select('_id correctIndex').lean();
  const chosen = lastAnswers(attempt.answers, attempt.expiresAt);
  const score = questions.filter((q) => chosen.get(q._id.toString()) === q.correctIndex).length;

  // Une remise tardive est datée de l'heure de fin : la durée ne dépasse jamais le temps imparti.
  const submittedAt = new Date(Math.min(now.getTime(), attempt.expiresAt.getTime()));
  const durationSeconds = Math.max(0, Math.round((submittedAt.getTime() - attempt.startedAt.getTime()) / 1000));

  return Attempt.findOneAndUpdate(
    { _id: attempt._id, status: 'in_progress' },
    { status: 'submitted', submittedAt, score, total: questions.length, durationSeconds },
    { returnDocument: 'after' },
  );
}

/**
 * Tentatives abandonnées (temps écoulé, jamais remises) : on les corrige avec
 * les réponses enregistrées à temps, pour qu'elles comptent au classement.
 */
export async function finalizeExpiredAttempts(filter: Record<string, unknown>) {
  const expired = await Attempt.find({
    ...filter,
    status: 'in_progress',
    expiresAt: { $lt: new Date(Date.now() - GRACE_MS) },
  });
  for (const attempt of expired) await finalize(attempt);
}
