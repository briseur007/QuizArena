import { describe, expect, it } from 'vitest';
import { api, classroom, createCourse, createQuiz, joinCourse, question, registerUser } from './helpers.js';

const draft = {
  title: 'API & sécurité',
  durationMinutes: 15,
  maxAttempts: 1,
  questions: [{ text: 'Où stocker les jetons ?', options: ['Prefs', 'Sécurisé', '', ''], correctIndex: null }],
};

describe('Quiz — enseignant', () => {
  it('crée un brouillon incomplet puis le relit avec les bonnes réponses', async () => {
    const teacher = await registerUser('teacher');
    const course = await createCourse(teacher);

    const created = await api().post(`/courses/${course.id}/quizzes`).set(teacher.auth).send(draft).expect(201);
    expect(created.body).toMatchObject({ title: 'API & sécurité', status: 'draft' });

    const full = await api().get(`/quizzes/${created.body.id}`).set(teacher.auth).expect(200);
    expect(full.body.questions[0]).toMatchObject({ text: 'Où stocker les jetons ?', correctIndex: null });
  });

  it('modifie le brouillon (remplacement complet des questions)', async () => {
    const teacher = await registerUser('teacher');
    const course = await createCourse(teacher);
    const quiz = await createQuiz(teacher, course.id, { publish: false });

    const res = await api()
      .patch(`/quizzes/${quiz.id}`)
      .set(teacher.auth)
      .send({ ...draft, title: 'Nouveau titre', questions: [question('Seule question', 3)] })
      .expect(200);
    expect(res.body.title).toBe('Nouveau titre');
    expect(res.body.questions).toHaveLength(1);
    expect(res.body.questions[0].correctIndex).toBe(3);
  });

  it('publication refusée (422) si une question est incomplète', async () => {
    const teacher = await registerUser('teacher');
    const course = await createCourse(teacher);
    const created = await api().post(`/courses/${course.id}/quizzes`).set(teacher.auth).send(draft).expect(201);

    const res = await api().post(`/quizzes/${created.body.id}/publish`).set(teacher.auth).expect(422);
    expect(res.body.error.code).toBe('QUIZ_INCOMPLETE');
    expect(res.body.error.details.questions).toEqual(['Question 1 incomplète']);
  });

  it('un quiz publié ne peut plus être modifié ni republié (409)', async () => {
    const teacher = await registerUser('teacher');
    const course = await createCourse(teacher);
    const quiz = await createQuiz(teacher, course.id);

    await api().patch(`/quizzes/${quiz.id}`).set(teacher.auth).send(draft).expect(409);
    await api().post(`/quizzes/${quiz.id}/publish`).set(teacher.auth).expect(409);
  });

  it('fermeture d’un quiz ouvert', async () => {
    const teacher = await registerUser('teacher');
    const course = await createCourse(teacher);
    const quiz = await createQuiz(teacher, course.id);
    const res = await api().post(`/quizzes/${quiz.id}/close`).set(teacher.auth).expect(200);
    expect(res.body.status).toBe('closed');
  });

  it('A9 : filtre par statut sur « mes quiz »', async () => {
    const teacher = await registerUser('teacher');
    const course = await createCourse(teacher);
    await createQuiz(teacher, course.id, { publish: false });
    await createQuiz(teacher, course.id);

    const open = await api().get('/quizzes?status=open').set(teacher.auth).expect(200);
    expect(open.body.items.map((q: { status: string }) => q.status)).toEqual(['open']);
    await api().get('/quizzes?status=bidon').set(teacher.auth).expect(422);
  });
});

describe('Quiz — autorisations (A7)', () => {
  it('un autre enseignant ne voit ni ne modifie le quiz (404)', async () => {
    const { quiz, course } = await classroom();
    const intruder = await registerUser('teacher');

    await api().get(`/quizzes/${quiz.id}`).set(intruder.auth).expect(404);
    await api().patch(`/quizzes/${quiz.id}`).set(intruder.auth).send(draft).expect(404);
    await api().post(`/quizzes/${quiz.id}/publish`).set(intruder.auth).expect(404);
    await api().get(`/quizzes/${quiz.id}/report`).set(intruder.auth).expect(404);
    await api().post(`/courses/${course.id}/quizzes`).set(intruder.auth).send(draft).expect(404);
  });

  it('règle T17 : un étudiant ne peut pas lire le quiz complet avec les réponses (403)', async () => {
    const { quiz, student } = await classroom();
    await api().get(`/quizzes/${quiz.id}`).set(student.auth).expect(403);
  });

  it('l’étudiant ne voit pas les brouillons du cours', async () => {
    const { teacher, student, course } = await classroom();
    await createQuiz(teacher, course.id, { publish: false });

    const res = await api().get(`/courses/${course.id}/quizzes`).set(student.auth).expect(200);
    expect(res.body.items.map((q: { status: string }) => q.status)).toEqual(['open']);
  });

  it('un étudiant non inscrit ne voit pas les quiz du cours (404)', async () => {
    const { course } = await classroom();
    const outsider = await registerUser('student');
    await api().get(`/courses/${course.id}/quizzes`).set(outsider.auth).expect(404);
  });

  it('identifiant mal formé : 422 ; inexistant : 404', async () => {
    const teacher = await registerUser('teacher');
    await api().get('/quizzes/pas-un-id').set(teacher.auth).expect(422);
    await api().get('/quizzes/0123456789abcdef01234567').set(teacher.auth).expect(404);
  });
});

describe('GET /quizzes?todo=true — quiz à faire de l’étudiant', () => {
  it('liste les quiz ouverts de ses cours avec des tentatives restantes', async () => {
    const teacher = await registerUser('teacher');
    const course = await createCourse(teacher);
    const other = await createCourse(teacher, 'Autre cours');
    const student = await registerUser('student');
    await joinCourse(student, course.code);
    const quiz = await createQuiz(teacher, course.id);
    await createQuiz(teacher, other.id); // cours non rejoint
    await createQuiz(teacher, course.id, { publish: false }); // brouillon

    const res = await api().get('/quizzes?todo=true').set(student.auth).expect(200);
    expect(res.body.items).toHaveLength(1);
    expect(res.body.items[0]).toMatchObject({ id: quiz.id, attemptsUsed: 0, maxAttempts: 1, courseName: 'Développement mobile' });
  });
});
