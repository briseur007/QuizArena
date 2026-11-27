import { describe, expect, it } from 'vitest';
import { api, createCourse, joinCourse, registerUser } from './helpers.js';

describe('Cours', () => {
  it('l’enseignant crée un cours ; un code d’invitation est généré', async () => {
    const teacher = await registerUser('teacher', 'Dr Nikiema');
    const res = await api().post('/courses').set(teacher.auth).send({ name: 'Développement mobile', level: 'L3' }).expect(201);
    expect(res.body).toMatchObject({
      name: 'Développement mobile',
      level: 'L3',
      teacherName: 'Dr Nikiema',
      studentCount: 0,
      quizCount: 0,
    });
    expect(res.body.code).toMatch(/^[A-Z0-9]{6}$/);
  });

  it('A7 rôle : un étudiant ne peut pas créer de cours (403)', async () => {
    const student = await registerUser('student');
    const res = await api().post('/courses').set(student.auth).send({ name: 'Cours pirate' }).expect(403);
    expect(res.body.error.code).toBe('FORBIDDEN');
  });

  it('401 sans authentification', async () => {
    await api().get('/courses').expect(401);
  });

  describe('rejoindre avec un code', () => {
    it('l’étudiant rejoint le cours (code insensible à la casse)', async () => {
      const teacher = await registerUser('teacher');
      const course = await createCourse(teacher);
      const student = await registerUser('student');

      const res = await api().post('/courses/join').set(student.auth).send({ code: course.code.toLowerCase() }).expect(200);
      expect(res.body).toMatchObject({ id: course.id, studentCount: 1 });
      // Le code n'est jamais montré à l'étudiant.
      expect(res.body.code).toBeUndefined();
    });

    it('409 si déjà inscrit, 404 si code inconnu, 422 si mal formé', async () => {
      const teacher = await registerUser('teacher');
      const course = await createCourse(teacher);
      const student = await registerUser('student');
      await joinCourse(student, course.code);

      expect((await api().post('/courses/join').set(student.auth).send({ code: course.code }).expect(409)).body.error.code).toBe(
        'ALREADY_ENROLLED',
      );
      await api().post('/courses/join').set(student.auth).send({ code: 'ZZZZ99' }).expect(404);
      await api().post('/courses/join').set(student.auth).send({ code: 'a!' }).expect(422);
    });

    it('un enseignant ne « rejoint » pas un cours (403)', async () => {
      const teacher = await registerUser('teacher');
      const course = await createCourse(teacher);
      await api().post('/courses/join').set(teacher.auth).send({ code: course.code }).expect(403);
    });
  });

  describe('GET /courses — chacun ne voit que ses cours (A7 objet)', () => {
    it('étudiant : uniquement les cours rejoints ; enseignant : uniquement les siens', async () => {
      const teacherA = await registerUser('teacher');
      const teacherB = await registerUser('teacher');
      const courseA = await createCourse(teacherA, 'Cours A');
      await createCourse(teacherB, 'Cours B');
      const student = await registerUser('student');
      await joinCourse(student, courseA.code);

      const forStudent = await api().get('/courses').set(student.auth).expect(200);
      expect(forStudent.body.items.map((c: { name: string }) => c.name)).toEqual(['Cours A']);

      const forB = await api().get('/courses').set(teacherB.auth).expect(200);
      expect(forB.body.items.map((c: { name: string }) => c.name)).toEqual(['Cours B']);
    });

    it('A9 : pagination plafonnée et recherche par nom', async () => {
      const teacher = await registerUser('teacher');
      for (const name of ['Bases de données', 'Développement mobile', 'Réseaux']) await createCourse(teacher, name);

      const page = await api().get('/courses?limit=2&page=2').set(teacher.auth).expect(200);
      expect(page.body).toMatchObject({ page: 2, limit: 2, total: 3 });
      expect(page.body.items).toHaveLength(1);

      await api().get('/courses?limit=500').set(teacher.auth).expect(422);

      const search = await api().get('/courses?q=mobile').set(teacher.auth).expect(200);
      expect(search.body.items.map((c: { name: string }) => c.name)).toEqual(['Développement mobile']);
    });
  });
});
