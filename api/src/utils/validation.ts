import mongoose from 'mongoose';
import { z } from 'zod';

/**
 * A4 : schémas partagés. Les objets Zod ignorent les champs inconnus
 * (comportement par défaut de `z.object`), donc un client ne peut pas
 * injecter `role`, `teacherId`, `score`… dans un corps de requête.
 */
export const objectId = z
  .string()
  .refine((v) => mongoose.isValidObjectId(v) && /^[a-f0-9]{24}$/i.test(v), 'Identifiant invalide');

export const idParams = z.object({ id: objectId });

/** A9 : pagination, taille de page plafonnée. */
export const MAX_PAGE_SIZE = 50;
export const paginationQuery = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(MAX_PAGE_SIZE).default(20),
});

export type Pagination = z.infer<typeof paginationQuery>;

export function paginate<T>(items: T[], total: number, { page, limit }: Pagination) {
  return { items, page, limit, total };
}

export const skipFor = ({ page, limit }: Pagination) => (page - 1) * limit;

/** Booléen de query string : « true » / « false ». */
export const queryBoolean = z
  .enum(['true', 'false'])
  .optional()
  .transform((v) => v === 'true');
