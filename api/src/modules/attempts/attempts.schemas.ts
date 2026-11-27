import { z } from 'zod';
import { MAX_QUESTIONS, OPTION_COUNT } from '../quizzes/quizzes.schemas.js';
import { objectId, paginationQuery } from '../../utils/validation.js';

const answer = z.object({
  questionId: objectId,
  optionIndex: z
    .number()
    .int()
    .min(0)
    .max(OPTION_COUNT - 1),
});

export const saveAnswerBody = answer;

export const submitBody = z.object({
  answers: z.array(answer).max(MAX_QUESTIONS).default([]),
});

export const leaderboardQuery = paginationQuery;
