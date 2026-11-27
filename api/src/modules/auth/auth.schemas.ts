import { z } from 'zod';

const email = z.string().trim().toLowerCase().pipe(z.email('Adresse e-mail invalide').max(254));

export const registerBody = z.object({
  name: z.string().trim().min(2, 'Nom trop court').max(80),
  email,
  password: z.string().min(8, 'Au moins 8 caractères').max(128),
  role: z.enum(['student', 'teacher']),
});

export const loginBody = z.object({
  email,
  password: z.string().min(1, 'Mot de passe requis').max(128),
});

export const refreshBody = z.object({
  refreshToken: z.string().min(10).max(200),
});
