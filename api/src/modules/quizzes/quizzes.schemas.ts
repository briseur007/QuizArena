import { z } from 'zod';
import { paginationQuery, queryBoolean } from '../../utils/validation.js';

export const OPTION_COUNT = 4;
export const MAX_QUESTIONS = 50;

/** Une question de brouillon peut être incomplète ; la publication vérifie tout. */
const questionDraft = z.object({
  text: z.string().trim().max(500).default(''),
  options: z.array(z.string().trim().max(200)).length(OPTION_COUNT, '4 réponses attendues'),
  correctIndex: z
    .number()
    .int()
    .min(0)
    .max(OPTION_COUNT - 1)
    .nullable()
    .default(null),
  explanation: z.string().trim().max(500).default(''),
});

/** Corps de création et de modification (remplacement complet du brouillon). */
export const quizDraftBody = z.object({
  title: z.string().trim().min(3, 'Titre trop court').max(120),
  durationMinutes: z.number().int().min(1).max(180),
  maxAttempts: z.number().int().min(1).max(10),
  questions: z.array(questionDraft).max(MAX_QUESTIONS).default([]),
});

export type QuizDraftInput = z.infer<typeof quizDraftBody>;

export const listQuizzesQuery = paginationQuery.extend({
  // A9 : filtres. Étudiant : `todo=true` (ouverts et encore jouables).
  todo: queryBoolean,
  status: z.enum(['draft', 'open', 'closed']).optional(),
});
