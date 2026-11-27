import { Types } from 'mongoose';
import type { z } from 'zod';
import type { AuthUser } from '../../middlewares/auth.js';
import { conflict, notFound, unprocessable } from '../../middlewares/error.js';
import { User } from '../auth/user.model.js';
import { Course } from '../courses/course.model.js';
import { findAccessibleCourse } from '../courses/courses.service.js';
import { Question } from '../quizzes/question.model.js';
import { Quiz } from '../quizzes/quiz.model.js';
import { findVisibleQuiz } from '../quizzes/quizzes.service.js';
import { Attempt, type AttemptDoc } from './attempt.model.js';
import type { leaderboardQuery, submitBody } from './attempts.schemas.js';
import { finalize, finalizeExpiredAttempts, isExpired, lastAnswers } from './grading.js';

const toId = (id: string) => new Types.ObjectId(id);

// ---------------------------------------------------------------------------
// Passage du quiz (écran 03)
// ---------------------------------------------------------------------------

/** Tentative telle que l'étudiant la reçoit : SANS `correctIndex` ni explication. */
async function toAttemptDto(attempt: AttemptDoc, quizTitle: string) {
  // Projection explicite : la bonne réponse ne quitte jamais le serveur avant la remise.
  const questions = await Question.find({ quizId: attempt.quizId })
    .select('_id text options order')
    .sort({ order: 1 })
    .lean();
  return {
    id: attempt._id.toString(),
    quizId: attempt.quizId.toString(),
    quizTitle,
    startedAt: attempt.startedAt.toISOString(),
    expiresAt: attempt.expiresAt.toISOString(),
    serverTime: new Date().toISOString(),
    questions: questions.map((q) => ({ id: q._id.toString(), text: q.text ?? '', options: q.options })),
    answers: Object.fromEntries(lastAnswers(attempt.answers, attempt.expiresAt)),
  };
}

/**
 * Démarre une tentative, ou reprend celle en cours.
 * Règles : quiz ouvert, étudiant inscrit, tentatives restantes.
 */
export async function start(user: AuthUser, quizId: string) {
  const quiz = await findVisibleQuiz(quizId, user);
  if (quiz.status !== 'open') throw conflict('Ce quiz est fermé', 'QUIZ_CLOSED');

  const current = await Attempt.findOne({ quizId: quiz._id, studentId: user.id, status: 'in_progress' });
  if (current && !isExpired(current)) return { created: false, attempt: await toAttemptDto(current, quiz.title) };
  if (current) await finalize(current); // temps écoulé : on clôt l'ancienne

  const used = await Attempt.countDocuments({ quizId: quiz._id, studentId: user.id, status: 'submitted' });
  if (used >= quiz.maxAttempts) {
    throw conflict('Tu as utilisé toutes tes tentatives pour ce quiz', 'NO_ATTEMPT_LEFT');
  }

  const startedAt = new Date();
  try {
    const attempt = await Attempt.create({
      quizId: quiz._id,
      courseId: quiz.courseId,
      studentId: user.id,
      attemptNumber: used + 1,
      startedAt,
      expiresAt: new Date(startedAt.getTime() + quiz.durationMinutes * 60_000),
    });
    return { created: true, attempt: await toAttemptDto(attempt, quiz.title) };
  } catch (err) {
    // Deux démarrages simultanés : l'index unique n'en laisse passer qu'un ;
    // l'autre reprend la tentative créée.
    if (!isDuplicateKey(err)) throw err;
    const winner = await Attempt.findOne({ quizId: quiz._id, studentId: user.id, status: 'in_progress' });
    if (!winner) throw conflict('Tu as utilisé toutes tes tentatives pour ce quiz', 'NO_ATTEMPT_LEFT');
    return { created: false, attempt: await toAttemptDto(winner, quiz.title) };
  }
}

/** Tentative de l'étudiant connecté, sinon 404 (on ne révèle pas celles des autres). */
async function findOwnAttempt(user: AuthUser, attemptId: string) {
  const attempt = await Attempt.findOne({ _id: attemptId, studentId: user.id });
  if (!attempt) throw notFound('Tentative introuvable');
  return attempt;
}

/** Enregistre une réponse au fil de l'eau. Refusée après la fin du temps. */
export async function saveAnswer(user: AuthUser, attemptId: string, questionId: string, optionIndex: number) {
  const attempt = await findOwnAttempt(user, attemptId);
  if (attempt.status === 'submitted') throw conflict('Ce quiz est déjà remis', 'ATTEMPT_SUBMITTED');
  if (isExpired(attempt)) throw conflict('Le temps est écoulé', 'ATTEMPT_EXPIRED');
  if (!(await Question.exists({ _id: questionId, quizId: attempt.quizId }))) {
    throw unprocessable('Cette question ne fait pas partie du quiz', { questionId: ['Question inconnue'] });
  }

  const answeredAt = new Date();
  const qid = toId(questionId);
  // Remplace la réponse existante… ou l'ajoute. Le filtre sur `in_progress`
  // évite d'écrire dans une tentative remise entre-temps.
  const replaced = await Attempt.updateOne(
    { _id: attempt._id, status: 'in_progress', 'answers.questionId': qid },
    { $set: { 'answers.$.optionIndex': optionIndex, 'answers.$.answeredAt': answeredAt } },
  );
  if (replaced.matchedCount === 0) {
    const added = await Attempt.updateOne(
      { _id: attempt._id, status: 'in_progress' },
      { $push: { answers: { questionId: qid, optionIndex, answeredAt } } },
    );
    if (added.matchedCount === 0) throw conflict('Ce quiz est déjà remis', 'ATTEMPT_SUBMITTED');
  }
}

/**
 * Remise. À temps : les réponses du corps complètent celles déjà enregistrées.
 * En retard : seules les réponses enregistrées avant la fin comptent.
 */
export async function submit(user: AuthUser, attemptId: string, input: z.infer<typeof submitBody>) {
  const attempt = await findOwnAttempt(user, attemptId);
  if (attempt.status === 'submitted') throw conflict('Ce quiz est déjà remis', 'ATTEMPT_SUBMITTED');

  const now = new Date();
  if (!isExpired(attempt, now) && input.answers.length > 0) {
    const valid = new Set(
      (await Question.find({ quizId: attempt.quizId }).select('_id').lean()).map((q) => q._id.toString()),
    );
    for (const a of input.answers) {
      if (valid.has(a.questionId)) {
        attempt.answers.push({ questionId: toId(a.questionId), optionIndex: a.optionIndex, answeredAt: now });
      }
    }
  }

  const graded = await finalize(attempt, now);
  if (!graded) throw conflict('Ce quiz est déjà remis', 'ATTEMPT_SUBMITTED');
  // Les réponses du corps ont servi à la correction ; on les conserve pour le rapport.
  await Attempt.updateOne({ _id: graded._id }, { answers: attempt.answers });
  graded.answers = attempt.answers;
  return toResultDto(graded);
}

// ---------------------------------------------------------------------------
// Résultats (écran 04)
// ---------------------------------------------------------------------------

async function toResultDto(attempt: AttemptDoc) {
  const [quiz, course, student, questions] = await Promise.all([
    Quiz.findById(attempt.quizId).select('title maxAttempts').lean(),
    Course.findById(attempt.courseId).select('name').lean(),
    User.findById(attempt.studentId).select('name').lean(),
    // Après la remise seulement : bonnes réponses et explications.
    Question.find({ quizId: attempt.quizId }).sort({ order: 1 }).lean(),
  ]);
  const chosen = lastAnswers(attempt.answers, attempt.expiresAt);

  return {
    id: attempt._id.toString(),
    quizId: attempt.quizId.toString(),
    courseId: attempt.courseId.toString(),
    quizTitle: quiz?.title ?? '',
    courseName: course?.name ?? '',
    studentName: student?.name ?? '',
    score: attempt.score,
    total: attempt.total,
    durationSeconds: attempt.durationSeconds,
    attemptNumber: attempt.attemptNumber,
    maxAttempts: quiz?.maxAttempts ?? 1,
    submittedAt: attempt.submittedAt?.toISOString(),
    corrections: questions.map((q, index) => {
      const pick = chosen.get(q._id.toString());
      return {
        index,
        question: q.text ?? '',
        chosenAnswer: pick === undefined ? null : (q.options[pick] ?? null),
        isCorrect: pick !== undefined && pick === q.correctIndex,
        correctAnswer: q.correctIndex == null ? '' : (q.options[q.correctIndex] ?? ''),
        explanation: q.explanation || null,
      };
    }),
  };
}

/**
 * Résultat d'une tentative : l'étudiant qui l'a passée, ou l'enseignant du cours.
 * Jamais avant la remise : la correction contient les bonnes réponses.
 */
export async function result(user: AuthUser, attemptId: string) {
  let attempt = await Attempt.findById(attemptId);
  if (!attempt) throw notFound('Tentative introuvable');

  const allowed =
    user.role === 'student'
      ? attempt.studentId.toString() === user.id
      : Boolean(await Quiz.exists({ _id: attempt.quizId, teacherId: user.id }));
  if (!allowed) throw notFound('Tentative introuvable');

  if (attempt.status === 'in_progress') {
    if (!isExpired(attempt)) throw conflict('Ce quiz n’est pas encore remis', 'ATTEMPT_IN_PROGRESS');
    attempt = (await finalize(attempt)) ?? (await Attempt.findById(attemptId));
    if (!attempt) throw notFound('Tentative introuvable');
  }
  return toResultDto(attempt);
}

/** Dernier quiz remis par l'étudiant (ligne « Dernier quiz : 8/10 »). */
export async function latest(user: AuthUser) {
  await finalizeExpiredAttempts({ studentId: toId(user.id) });
  const attempt = await Attempt.findOne({ studentId: user.id, status: 'submitted' }).sort({ submittedAt: -1 });
  if (!attempt) throw notFound('Aucun quiz remis', 'NO_RESULT');
  return toResultDto(attempt);
}

// ---------------------------------------------------------------------------
// Classement (écran 05) : agrégations MongoDB
// ---------------------------------------------------------------------------

interface Row {
  _id: Types.ObjectId; // studentId
  score: number;
  total: number;
  durationSeconds: number;
}

async function toLeaderboard(title: string, rows: Row[], user: AuthUser, limit: number) {
  const top = rows.slice(0, limit);
  const names = new Map(
    (
      await User.find({ _id: { $in: top.map((r) => r._id) } })
        .select('name')
        .lean()
    ).map((u) => [u._id.toString(), u.name]),
  );
  return {
    title,
    participants: rows.length,
    entries: top.map((r, i) => ({
      rank: i + 1,
      name: names.get(r._id.toString()) ?? 'Étudiant',
      score: r.score,
      total: r.total,
      durationSeconds: r.durationSeconds,
      isMe: r._id.toString() === user.id,
    })),
  };
}

/** Meilleure tentative de chaque étudiant sur le quiz ; tri : score, puis durée. */
export async function quizLeaderboard(user: AuthUser, quizId: string, query: z.infer<typeof leaderboardQuery>) {
  const quiz = await findVisibleQuiz(quizId, user);
  await finalizeExpiredAttempts({ quizId: quiz._id });

  const rows = await Attempt.aggregate<Row>([
    { $match: { quizId: quiz._id, status: 'submitted' } },
    { $sort: { score: -1, durationSeconds: 1 } },
    {
      $group: {
        _id: '$studentId',
        score: { $first: '$score' },
        total: { $first: '$total' },
        durationSeconds: { $first: '$durationSeconds' },
      },
    },
    { $sort: { score: -1, durationSeconds: 1, _id: 1 } },
  ]);
  return toLeaderboard(quiz.title, rows, user, query.limit);
}

/** Cumul des meilleures tentatives de chaque étudiant sur tous les quiz du cours. */
export async function courseLeaderboard(user: AuthUser, courseId: string, query: z.infer<typeof leaderboardQuery>) {
  const course = await findAccessibleCourse(courseId, user);
  await finalizeExpiredAttempts({ courseId: course._id });

  const rows = await Attempt.aggregate<Row>([
    { $match: { courseId: course._id, status: 'submitted' } },
    { $sort: { score: -1, durationSeconds: 1 } },
    // 1. meilleure tentative par (étudiant, quiz)
    {
      $group: {
        _id: { student: '$studentId', quiz: '$quizId' },
        score: { $first: '$score' },
        total: { $first: '$total' },
        durationSeconds: { $first: '$durationSeconds' },
      },
    },
    // 2. cumul par étudiant
    {
      $group: {
        _id: '$_id.student',
        score: { $sum: '$score' },
        total: { $sum: '$total' },
        durationSeconds: { $sum: '$durationSeconds' },
      },
    },
    { $sort: { score: -1, durationSeconds: 1, _id: 1 } },
  ]);
  return toLeaderboard(course.name, rows, user, query.limit);
}

function isDuplicateKey(err: unknown): boolean {
  return typeof err === 'object' && err !== null && 'code' in err && err.code === 11000;
}
