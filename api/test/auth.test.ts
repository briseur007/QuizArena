import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { Session } from '../src/modules/auth/session.model.js';
import { User } from '../src/modules/auth/user.model.js';
import { api, registerUser } from './helpers.js';

const amina = { name: 'Amina Ouédraogo', email: 'amina@universite.bf', password: 'Password123!', role: 'student' };

describe('POST /auth/register', () => {
  it('crée le compte, ouvre une session et ne renvoie jamais le mot de passe', async () => {
    const res = await api().post('/auth/register').send(amina).expect(201);

    expect(res.body.user).toMatchObject({ name: amina.name, email: amina.email, role: 'student', level: 1 });
    expect(res.body.accessToken).toEqual(expect.any(String));
    expect(res.body.refreshToken).toEqual(expect.any(String));
    expect(JSON.stringify(res.body)).not.toMatch(/password/i);
  });

  it('A6 : mot de passe haché en Argon2id, refresh token stocké haché', async () => {
    const res = await api().post('/auth/register').send(amina).expect(201);

    const user = await User.findOne({ email: amina.email }).select('+passwordHash').lean();
    expect(user?.passwordHash).toMatch(/^\$argon2id\$/);
    const session = await Session.findOne({ userId: user?._id }).lean();
    expect(session?.tokenHash).toMatch(/^[a-f0-9]{64}$/);
    expect(res.body.refreshToken).not.toContain(session?.tokenHash);
  });

  it('A4 : champs inconnus ignorés, e-mail normalisé', async () => {
    const res = await api()
      .post('/auth/register')
      .send({ ...amina, email: '  AMINA@Universite.BF ', isAdmin: true, level: 99 })
      .expect(201);
    expect(res.body.user.email).toBe('amina@universite.bf');
    expect(res.body.user.level).toBe(1);
    expect(res.body.user.isAdmin).toBeUndefined();
  });

  it('422 avec les erreurs par champ', async () => {
    const res = await api()
      .post('/auth/register')
      .send({ name: 'A', email: 'pas-un-email', password: '123', role: 'admin' })
      .expect(422);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(Object.keys(res.body.error.details)).toEqual(expect.arrayContaining(['name', 'email', 'password', 'role']));
  });

  it('409 si l’e-mail est déjà pris', async () => {
    await api().post('/auth/register').send(amina).expect(201);
    const res = await api().post('/auth/register').send(amina).expect(409);
    expect(res.body.error.code).toBe('EMAIL_TAKEN');
  });
});

describe('POST /auth/login', () => {
  it('connecte avec les bons identifiants', async () => {
    await api().post('/auth/register').send(amina).expect(201);
    const res = await api().post('/auth/login').send({ email: amina.email, password: amina.password }).expect(200);
    expect(res.body.user.email).toBe(amina.email);
  });

  it('401 identique pour un mauvais mot de passe et un e-mail inconnu', async () => {
    await api().post('/auth/register').send(amina).expect(201);
    const wrong = await api().post('/auth/login').send({ email: amina.email, password: 'mauvais' }).expect(401);
    const unknown = await api().post('/auth/login').send({ email: 'x@y.bf', password: 'mauvais' }).expect(401);
    expect(wrong.body).toEqual(unknown.body);
  });
});

describe('GET /auth/me', () => {
  it('renvoie le profil avec un jeton valide', async () => {
    const user = await registerUser('teacher', 'Dr Nikiema');
    const res = await api().get('/auth/me').set(user.auth).expect(200);
    expect(res.body).toMatchObject({ id: user.id, name: 'Dr Nikiema', role: 'teacher' });
  });

  it('401 sans jeton ou avec un jeton falsifié', async () => {
    await api().get('/auth/me').expect(401);
    const user = await registerUser('student');
    const forged = `${user.token.slice(0, -4)}abcd`;
    const res = await api().get('/auth/me').set('Authorization', `Bearer ${forged}`).expect(401);
    expect(res.body.error.code).toBe('TOKEN_INVALID');
  });
});

describe('PATCH /auth/me — modifier son profil', () => {
  it('modifie le nom et l’e-mail ; la connexion se fait avec le nouvel e-mail', async () => {
    const user = await registerUser('teacher', 'Dr Nikiema');
    const res = await api()
      .patch('/auth/me')
      .set(user.auth)
      .send({ name: 'Pr Nikiema', email: 'Nouveau@Universite.BF' })
      .expect(200);
    expect(res.body).toMatchObject({ id: user.id, name: 'Pr Nikiema', email: 'nouveau@universite.bf', role: 'teacher' });

    await api().post('/auth/login').send({ email: 'nouveau@universite.bf', password: 'Password123!' }).expect(200);
  });

  it('A4/A7 : le rôle ne peut pas être changé (champ ignoré)', async () => {
    const student = await registerUser('student');
    const res = await api().patch('/auth/me').set(student.auth).send({ name: 'Amina', role: 'teacher' }).expect(200);
    expect(res.body.role).toBe('student');
    // Et il n'a toujours pas les droits d'un enseignant.
    await api().post('/courses').set(student.auth).send({ name: 'Cours pirate' }).expect(403);
  });

  it('409 si l’e-mail appartient à un autre compte ; 422 si rien à modifier', async () => {
    await api().post('/auth/register').send(amina).expect(201);
    const user = await registerUser('teacher');
    const taken = await api().patch('/auth/me').set(user.auth).send({ email: amina.email }).expect(409);
    expect(taken.body.error.code).toBe('EMAIL_TAKEN');
    await api().patch('/auth/me').set(user.auth).send({}).expect(422);
    await api().patch('/auth/me').send({ name: 'Sans jeton' }).expect(401);
  });
});

describe('PATCH /auth/me/password — changer son mot de passe', () => {
  it('exige le mot de passe actuel (422 sur le champ si incorrect)', async () => {
    const user = await registerUser('teacher');
    const res = await api()
      .patch('/auth/me/password')
      .set(user.auth)
      .send({ currentPassword: 'mauvais', newPassword: 'NouveauMotDePasse1' })
      .expect(422);
    expect(res.body.error.details.currentPassword).toEqual(['Mot de passe actuel incorrect']);
  });

  it('change le mot de passe et révoque les autres sessions, pas la session courante', async () => {
    const user = await registerUser('teacher');
    const email = (await api().get('/auth/me').set(user.auth)).body.email;
    // Deuxième appareil connecté au même compte.
    const other = await api().post('/auth/login').send({ email, password: 'Password123!' }).expect(200);

    await api()
      .patch('/auth/me/password')
      .set(user.auth)
      .send({ currentPassword: 'Password123!', newPassword: 'NouveauMotDePasse1' })
      .expect(204);

    await api().post('/auth/login').send({ email, password: 'Password123!' }).expect(401);
    await api().post('/auth/login').send({ email, password: 'NouveauMotDePasse1' }).expect(200);
    await api().post('/auth/refresh').send({ refreshToken: other.body.refreshToken }).expect(401);
    await api().post('/auth/refresh').send({ refreshToken: user.refreshToken }).expect(200);
  });

  it('nouveau mot de passe trop court : 422', async () => {
    const user = await registerUser('student');
    await api()
      .patch('/auth/me/password')
      .set(user.auth)
      .send({ currentPassword: 'Password123!', newPassword: '123' })
      .expect(422);
  });
});

describe('POST /auth/refresh — rotation', () => {
  it('renvoie une nouvelle paire ; l’ancien refresh token ne marche plus', async () => {
    const user = await registerUser('student');
    const first = await api().post('/auth/refresh').send({ refreshToken: user.refreshToken }).expect(200);
    expect(first.body.refreshToken).not.toBe(user.refreshToken);
    await api().get('/auth/me').set('Authorization', `Bearer ${first.body.accessToken}`).expect(200);

    const replay = await api().post('/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
    expect(replay.body.error.code).toBe('REFRESH_REUSED');
  });

  it('rejouer un ancien token révoque toute la session (vol présumé)', async () => {
    const user = await registerUser('student');
    const rotated = await api().post('/auth/refresh').send({ refreshToken: user.refreshToken }).expect(200);
    await api().post('/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
    // Même le token légitime le plus récent est désormais refusé.
    await api().post('/auth/refresh').send({ refreshToken: rotated.body.refreshToken }).expect(401);
  });

  it('401 pour un token mal formé', async () => {
    await api().post('/auth/refresh').send({ refreshToken: 'nimportequoi-nimportequoi' }).expect(401);
  });
});

describe('POST /auth/logout', () => {
  it('révoque la session : le refresh token est refusé ensuite', async () => {
    const user = await registerUser('student');
    await api().post('/auth/logout').send({ refreshToken: user.refreshToken }).expect(204);
    await api().post('/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
    // Idempotent.
    await api().post('/auth/logout').send({ refreshToken: user.refreshToken }).expect(204);
  });
});

describe('A11 : rate limiting sur /auth', () => {
  it('429 après trop de tentatives', async () => {
    const limited = createApp({ authRateLimit: 3 });
    for (let i = 0; i < 3; i++) {
      await request(limited).post('/auth/login').send({ email: 'x@y.bf', password: 'x' }).expect(401);
    }
    const res = await request(limited).post('/auth/login').send({ email: 'x@y.bf', password: 'x' }).expect(429);
    expect(res.body.error.code).toBe('TOO_MANY_REQUESTS');
  });

  it('helmet : en-têtes de sécurité présents', async () => {
    const res = await api().get('/health').expect(200);
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-powered-by']).toBeUndefined();
  });
});
