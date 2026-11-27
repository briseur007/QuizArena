import { describe, expect, it } from 'vitest';
import { Attempt } from '../src/modules/attempts/attempt.model.js';
import { api, classroom, joinCourse, registerUser, startAttempt, type TestUser } from './helpers.js';

/** Réponses : la bonne réponse de Qn est l'option n-1 (voir helpers.createQuiz). */
async function answer(student: TestUser, attemptId: string, questionId: string, optionIndex: number) {
  return api().put(`/attempts/${attemptId}/answers`).set(student.auth).send({ questionId, optionIndex });
}

describe('Passage d’un quiz — règles serveur T17', () => {
  it('les bonnes réponses ne sont JAMAIS envoyées avant la remise', async () => {
    const { student, quiz } = await classroom();
    const res = await api().post(`/quizzes/${quiz.id}/attempts`).set(student.auth).expect(201);

    expect(res.body.questions).toHaveLength(3);
    const body = JSON.stringify(res.body);
    expect(body).not.toContain('correctIndex');
    expect(body).not.toContain('Explication');
    // Et le résultat n'est pas consultable tant que le quiz n'est pas remis.
    const result = await api().get(`/attempts/${res.body.id}`).set(student.auth).expect(409);
    expect(result.body.error.code).toBe('ATTEMPT_IN_PROGRESS');
  });

  it('minuteur fixé par le serveur : expiresAt = début + durée', async () => {
    const { student, quiz } = await classroom();
    const before = Date.now();
    const attempt = await startAttempt(student, quiz.id);
    const ms = new Date(attempt.expiresAt).getTime() - before;
    expect(ms).toBeGreaterThan(10 * 60_000 - 5_000);
    expect(ms).toBeLessThanOrEqual(10 * 60_000 + 5_000);
  });

  it('reprise : redemander renvoie la même tentative (200) avec les réponses enregistrées', async () => {
    const { student, quiz } = await classroom();
    const first = await startAttempt(student, quiz.id);
    await answer(student, first.id, first.questions[0].id, 2).then((r) => expect(r.status).toBe(204));

    const again = await api().post(`/quizzes/${quiz.id}/attempts`).set(student.auth).expect(200);
    expect(again.body.id).toBe(first.id);
    expect(again.body.answers).toEqual({ [first.questions[0].id]: 2 });
  });

  it('correction automatique sur le serveur, puis correction détaillée', async () => {
    const { student, quiz } = await classroom();
    const attempt = await startAttempt(student, quiz.id);
    const [q1, q2, q3] = attempt.questions;
    await answer(student, attempt.id, q1.id, 3); // faux, puis corrigé…
    await answer(student, attempt.id, q1.id, 0); // …juste
    await answer(student, attempt.id, q2.id, 1); // juste

    const res = await api()
      .post(`/attempts/${attempt.id}/submit`)
      .set(student.auth)
      .send({ answers: [{ questionId: q3.id, optionIndex: 0 }] }) // faux
      .expect(200);

    expect(res.body).toMatchObject({ score: 2, total: 3, attemptNumber: 1, maxAttempts: 1, studentName: 'Amina Ouédraogo' });
    expect(res.body.corrections.map((c: { isCorrect: boolean }) => c.isCorrect)).toEqual([true, true, false]);
    expect(res.body.corrections[2]).toMatchObject({ chosenAnswer: 'Réponse A', correctAnswer: 'Réponse C' });
  });

  it('une seule tentative : la seconde est refusée (409 NO_ATTEMPT_LEFT)', async () => {
    const { student, quiz } = await classroom();
    const attempt = await startAttempt(student, quiz.id);
    await api().post(`/attempts/${attempt.id}/submit`).set(student.auth).send({}).expect(200);

    const res = await api().post(`/quizzes/${quiz.id}/attempts`).set(student.auth).expect(409);
    expect(res.body.error.code).toBe('NO_ATTEMPT_LEFT');
    // Pas de double remise non plus.
    await api().post(`/attempts/${attempt.id}/submit`).set(student.auth).send({}).expect(409);
  });

  it('« sauf autorisation » : maxAttempts = 2 permet une deuxième tentative', async () => {
    const { student, quiz } = await classroom({ maxAttempts: 2 });
    const first = await startAttempt(student, quiz.id);
    await api().post(`/attempts/${first.id}/submit`).set(student.auth).send({}).expect(200);
    const second = await api().post(`/quizzes/${quiz.id}/attempts`).set(student.auth).expect(201);
    expect(second.body.id).not.toBe(first.id);
  });

  it('démarrages simultanés : une seule tentative est créée', async () => {
    const { student, quiz } = await classroom();
    const responses = await Promise.all(
      Array.from({ length: 5 }, () => api().post(`/quizzes/${quiz.id}/attempts`).set(student.auth)),
    );
    expect(responses.every((r) => r.status === 200 || r.status === 201)).toBe(true);
    expect(new Set(responses.map((r) => r.body.id)).size).toBe(1);
    expect(await Attempt.countDocuments({ quizId: quiz.id })).toBe(1);
  });

  describe('temps écoulé', () => {
    /** Simule 11 minutes écoulées : toute la chronologie de la tentative recule. */
    async function expire(attemptId: string) {
      const shift = 11 * 60_000;
      const attempt = await Attempt.findById(attemptId);
      if (!attempt) throw new Error('tentative introuvable');
      attempt.startedAt = new Date(attempt.startedAt.getTime() - shift);
      attempt.expiresAt = new Date(attempt.expiresAt.getTime() - shift);
      for (const a of attempt.answers) a.answeredAt = new Date(a.answeredAt.getTime() - shift);
      await attempt.save();
    }

    it('une réponse arrivée après la fin est refusée (409 ATTEMPT_EXPIRED)', async () => {
      const { student, quiz } = await classroom();
      const attempt = await startAttempt(student, quiz.id);
      await expire(attempt.id);
      const res = await answer(student, attempt.id, attempt.questions[0].id, 0);
      expect(res.status).toBe(409);
      expect(res.body.error.code).toBe('ATTEMPT_EXPIRED');
    });

    it('remise tardive : seules les réponses enregistrées à temps comptent', async () => {
      const { student, quiz } = await classroom();
      const attempt = await startAttempt(student, quiz.id);
      const [q1, q2] = attempt.questions;
      await answer(student, attempt.id, q1.id, 0); // juste, à temps
      await expire(attempt.id);

      const res = await api()
        .post(`/attempts/${attempt.id}/submit`)
        .set(student.auth)
        .send({ answers: [{ questionId: q2.id, optionIndex: 1 }] }) // juste mais trop tard
        .expect(200);
      expect(res.body.score).toBe(1);
      expect(res.body.durationSeconds).toBe(600); // plafonnée au temps imparti
    });

    it('tentative abandonnée : corrigée automatiquement et comptée au classement', async () => {
      const { student, quiz } = await classroom();
      const attempt = await startAttempt(student, quiz.id);
      await answer(student, attempt.id, attempt.questions[0].id, 0);
      await expire(attempt.id);

      const board = await api().get(`/quizzes/${quiz.id}/leaderboard`).set(student.auth).expect(200);
      expect(board.body.entries[0]).toMatchObject({ score: 1, isMe: true });
    });
  });
});

describe('Tentatives — autorisations (A7)', () => {
  it('un autre étudiant ne peut ni répondre, ni remettre, ni voir le résultat (404)', async () => {
    const { student, quiz, course } = await classroom();
    const attempt = await startAttempt(student, quiz.id);
    const other = await registerUser('student');
    await joinCourse(other, course.code);

    expect((await answer(other, attempt.id, attempt.questions[0].id, 0)).status).toBe(404);
    await api().post(`/attempts/${attempt.id}/submit`).set(other.auth).send({}).expect(404);
    await api().post(`/attempts/${attempt.id}/submit`).set(student.auth).send({}).expect(200);
    await api().get(`/attempts/${attempt.id}`).set(other.auth).expect(404);
  });

  it('l’enseignant du cours voit le résultat ; un autre enseignant non', async () => {
    const { student, teacher, quiz } = await classroom();
    const attempt = await startAttempt(student, quiz.id);
    await api().post(`/attempts/${attempt.id}/submit`).set(student.auth).send({}).expect(200);

    await api().get(`/attempts/${attempt.id}`).set(teacher.auth).expect(200);
    const intruder = await registerUser('teacher');
    await api().get(`/attempts/${attempt.id}`).set(intruder.auth).expect(404);
  });

  it('un étudiant non inscrit ne peut pas démarrer le quiz (404) ; un enseignant non plus (403)', async () => {
    const { quiz, teacher } = await classroom();
    const outsider = await registerUser('student');
    await api().post(`/quizzes/${quiz.id}/attempts`).set(outsider.auth).expect(404);
    await api().post(`/quizzes/${quiz.id}/attempts`).set(teacher.auth).expect(403);
  });

  it('une question d’un autre quiz est refusée (422)', async () => {
    const { student, quiz } = await classroom();
    const attempt = await startAttempt(student, quiz.id);
    const res = await answer(student, attempt.id, '0123456789abcdef01234567', 0);
    expect(res.status).toBe(422);
  });
});

describe('Classement, rapport et dernier résultat', () => {
  /** Trois étudiants : Fatou 3/3, Ibrahim 2/3, Amina 2/3 mais plus lente. */
  async function scenario() {
    const ctx = await classroom();
    const fatou = await registerUser('student', 'Fatou Ouédraogo');
    const ibrahim = await registerUser('student', 'Ibrahim Traoré');
    for (const s of [fatou, ibrahim]) await joinCourse(s, ctx.course.code);

    async function play(student: TestUser, picks: number[], seconds: number) {
      const attempt = await startAttempt(student, ctx.quiz.id);
      const started = new Date(Date.now() - seconds * 1000);
      await Attempt.updateOne({ _id: attempt.id }, { startedAt: started });
      await api()
        .post(`/attempts/${attempt.id}/submit`)
        .set(student.auth)
        .send({ answers: attempt.questions.map((q, i) => ({ questionId: q.id, optionIndex: picks[i] })) })
        .expect(200);
      return attempt.id;
    }

    await play(fatou, [0, 1, 2], 342);
    await play(ibrahim, [0, 1, 3], 375);
    const aminaAttempt = await play(ctx.student, [0, 1, 0], 438);
    return { ...ctx, fatou, ibrahim, aminaAttempt };
  }

  it('classement du quiz : score, puis durée ; « isMe » pour l’utilisateur', async () => {
    const { student, quiz } = await scenario();
    const res = await api().get(`/quizzes/${quiz.id}/leaderboard`).set(student.auth).expect(200);

    expect(res.body.participants).toBe(3);
    expect(res.body.entries.map((e: { name: string }) => e.name)).toEqual(['Fatou Ouédraogo', 'Ibrahim Traoré', 'Amina Ouédraogo']);
    expect(res.body.entries.map((e: { rank: number }) => e.rank)).toEqual([1, 2, 3]);
    expect(res.body.entries[2]).toMatchObject({ score: 2, total: 3, isMe: true });
  });

  it('classement du cours : cumul des meilleures notes', async () => {
    const { fatou, course } = await scenario();
    const res = await api().get(`/courses/${course.id}/leaderboard`).set(fatou.auth).expect(200);
    expect(res.body.title).toBe('Développement mobile');
    expect(res.body.entries[0]).toMatchObject({ name: 'Fatou Ouédraogo', score: 3, isMe: true });
  });

  it('classement refusé hors du cours (404)', async () => {
    const { quiz } = await scenario();
    const outsider = await registerUser('student');
    await api().get(`/quizzes/${quiz.id}/leaderboard`).set(outsider.auth).expect(404);
  });

  it('rapport du quiz (écran 08) : remises, moyenne, réussite par question', async () => {
    const { teacher, quiz, student } = await scenario();
    const res = await api().get(`/quizzes/${quiz.id}/report`).set(teacher.auth).expect(200);

    expect(res.body).toMatchObject({ status: 'open', questionCount: 3, studentCount: 3, average: 2.3 });
    expect(res.body.submissions.map((s: { studentName: string }) => s.studentName)).toEqual([
      'Fatou Ouédraogo',
      'Ibrahim Traoré',
      'Amina Ouédraogo',
    ]);
    expect(res.body.questions.map((q: { correctCount: number }) => q.correctCount)).toEqual([3, 3, 1]);
    // Un étudiant n'a pas accès au rapport.
    await api().get(`/quizzes/${quiz.id}/report`).set(student.auth).expect(403);
  });

  it('dernier résultat de l’étudiant, et niveau qui progresse', async () => {
    const { student, aminaAttempt } = await scenario();
    const latest = await api().get('/attempts/me/latest').set(student.auth).expect(200);
    expect(latest.body).toMatchObject({ id: aminaAttempt, score: 2, total: 3 });

    const fresh = await registerUser('student');
    await api().get('/attempts/me/latest').set(fresh.auth).expect(404);
  });
});
