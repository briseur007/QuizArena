import request from 'supertest';
import { createApp } from '../src/app.js';

export const app = createApp();
export const api = () => request(app);

export interface TestUser {
  id: string;
  token: string;
  refreshToken: string;
  auth: { Authorization: string };
}

let counter = 0;

export async function registerUser(role: 'student' | 'teacher', name?: string): Promise<TestUser> {
  counter++;
  const res = await api()
    .post('/auth/register')
    .send({
      name: name ?? `${role === 'teacher' ? 'Prof' : 'Étudiant'} ${counter}`,
      email: `${role}${counter}-${Date.now()}@test.bf`,
      password: 'Password123!',
      role,
    })
    .expect(201);
  return {
    id: res.body.user.id,
    token: res.body.accessToken,
    refreshToken: res.body.refreshToken,
    auth: { Authorization: `Bearer ${res.body.accessToken}` },
  };
}

export async function createCourse(teacher: TestUser, name = 'Développement mobile') {
  const res = await api().post('/courses').set(teacher.auth).send({ name, level: 'L3' }).expect(201);
  return res.body as { id: string; code: string; name: string };
}

export async function joinCourse(student: TestUser, code: string) {
  await api().post('/courses/join').set(student.auth).send({ code }).expect(200);
}

/** Question complète ; la bonne réponse est toujours l'option [correct]. */
export const question = (text: string, correct = 0) => ({
  text,
  options: ['Réponse A', 'Réponse B', 'Réponse C', 'Réponse D'],
  correctIndex: correct,
  explanation: `Explication de « ${text} »`,
});

export async function createQuiz(
  teacher: TestUser,
  courseId: string,
  { publish = true, maxAttempts = 1, questions = [question('Q1', 0), question('Q2', 1), question('Q3', 2)] } = {},
) {
  const res = await api()
    .post(`/courses/${courseId}/quizzes`)
    .set(teacher.auth)
    .send({ title: 'Flutter & BLoC', durationMinutes: 10, maxAttempts, questions })
    .expect(201);
  if (publish) await api().post(`/quizzes/${res.body.id}/publish`).set(teacher.auth).expect(200);
  return res.body as { id: string; questions: { id: string }[] };
}

/** Scénario de base : un enseignant, un cours, un étudiant inscrit, un quiz publié. */
export async function classroom(options?: Parameters<typeof createQuiz>[2]) {
  const teacher = await registerUser('teacher', 'Dr Nikiema');
  const student = await registerUser('student', 'Amina Ouédraogo');
  const course = await createCourse(teacher);
  await joinCourse(student, course.code);
  const quiz = await createQuiz(teacher, course.id, options);
  return { teacher, student, course, quiz };
}

/** Démarre une tentative et renvoie son corps. */
export async function startAttempt(student: TestUser, quizId: string) {
  const res = await api().post(`/quizzes/${quizId}/attempts`).set(student.auth);
  if (res.status !== 201 && res.status !== 200) throw new Error(`start ${res.status} ${JSON.stringify(res.body)}`);
  return res.body as { id: string; questions: { id: string; text: string; options: string[] }[]; expiresAt: string };
}
