import { z } from 'zod';
import { paginationQuery } from '../../utils/validation.js';

export const createCourseBody = z.object({
  name: z.string().trim().min(3, 'Nom trop court').max(100),
  level: z.string().trim().max(20).default(''),
});

export const joinCourseBody = z.object({
  code: z
    .string()
    .trim()
    .toUpperCase()
    .regex(/^[A-Z0-9]{4,10}$/, 'Code invalide'),
});

export const listCoursesQuery = paginationQuery.extend({
  // A9 : recherche par nom.
  q: z.string().trim().max(100).optional(),
});
