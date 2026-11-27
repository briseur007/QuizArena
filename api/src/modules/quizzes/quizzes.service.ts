import { Types } from 'mongoose';
import type { z } from 'zod';
import type { AuthUser } from '../../middlewares/auth.js';
import { conflict, notFound, unprocessable } from '../../middlewares/error.js';
import { paginate, skipFor } from '../../utils/validation.js';
import { Attempt } from '../attempts/attempt.model.js';
import { finalizeExpiredAttempts, lastAnswers } from '../attempts/grading.js';
import { User } from '../auth/user.model.js';
import { Course } from '../courses/course.model.js';
import { findAccessibleCourse, findOwnedCourse, studentCourseIds } from '../courses/courses.service.js';
import { Enrollment } from '../courses/enrollment.model.js';
import { Question } from './question.model.js';
import { Quiz } from './quiz.model.js';
import { OPTION_COUNT, type QuizDraftInput, type listQuizzesQuery } from './quizzes.schemas.js';

type QuizDoc = InstanceType<typeof Quiz>;
type ListQuery = z.infer<typeof listQuizzesQuery>;

export interface QuizSummaryDto {
  id: string;
  courseId: string;
  courseName: string;
  courseLevel: string;
  title: string;
  durationMinutes: number;
  maxAttempts: number;
  questionCount: number;
  status: string;
  attemptsUsed: number;
  submissionCount: number;
  studentCount: number;
}

// ---------------------------------------------------------------------------
// Accès
// ---------------------------------------------------------------------------

/** Quiz de l'enseignant connecté, sinon 404. */
export async function findOwnedQuiz(quizId: string, teacherId: string): Promise<QuizDoc> {
  const quiz = await Quiz.findOne({ _id: quizId, teacherId });
  if (!quiz) throw notFound('Quiz introuvable');
  return quiz;
}

/**
 * Quiz visible par l'utilisateur : enseignant propriétaire, ou étudiant
 * inscrit au cours (et seulement s'il est publié).
 */
export async function findVisibleQuiz(quizId: string, user: AuthUser): Promise<QuizDoc> {
  const quiz = await Quiz.findById(quizId);
  if (!quiz) throw notFound('Quiz introuvable');
  if (user.role === 'teacher') {
    if (quiz.teacherId.toString() !== user.id) throw notFound('Quiz introuvable');
  } else {
    const enrolled = await Enrollment.exists({ courseId: quiz.courseId, studentId: user.id });
    if (!enrolled || quiz.status === 'draft') throw notFound('Quiz introuvable');
  }
  return quiz;
}

// ---------------------------------------------------------------------------
// Représentations renvoyées à l'app
// ---------------------------------------------------------------------------

async function toSummaries(quizzes: QuizDoc[], user: AuthUser): Promise<QuizSummaryDto[]> {
  if (quizzes.length === 0) return [];
  const quizIds = quizzes.map((q) => q._id);
  const courseIds = [...new Set(quizzes.map((q) => q.courseId.toString()))];

  const [courses, attempts, enrollments] = await Promise.all([
    Course.find({ _id: { $in: courseIds } })
      .select('name level')
      .lean(),
    user.role === 'student'
      ? // Tentatives remises par l'étudiant, par quiz.
        Attempt.aggregate<{ _id: Types.ObjectId; n: number }>([
          { $match: { quizId: { $in: quizIds }, studentId: toId(user.id), status: 'submitted' } },
          { $group: { _id: '$quizId', n: { $sum: 1 } } },
        ])
      : // Étudiants distincts ayant remis, par quiz.
        Attempt.aggregate<{ _id: Types.ObjectId; n: number }>([
          { $match: { quizId: { $in: quizIds }, status: 'submitted' } },
          { $group: { _id: { quiz: '$quizId', student: '$studentId' } } },
          { $group: { _id: '$_id.quiz', n: { $sum: 1 } } },
        ]),
    user.role === 'teacher'
      ? Enrollment.aggregate<{ _id: Types.ObjectId; n: number }>([
          { $match: { courseId: { $in: quizzes.map((q) => q.courseId) } } },
          { $group: { _id: '$courseId', n: { $sum: 1 } } },
        ])
      : Promise.resolve([]),
  ]);

  const courseById = new Map(courses.map((c) => [c._id.toString(), c]));
  const attemptsByQuiz = new Map(attempts.map((a) => [a._id.toString(), a.n]));
  const studentsByCourse = new Map(enrollments.map((e) => [e._id.toString(), e.n]));

  return quizzes.map((q) => {
    const course = courseById.get(q.courseId.toString());
    const n = attemptsByQuiz.get(q._id.toString()) ?? 0;
    return {
      id: q._id.toString(),
      courseId: q.courseId.toString(),
      courseName: course?.name ?? '',
      courseLevel: course?.level ?? '',
      title: q.title,
      durationMinutes: q.durationMinutes,
      maxAttempts: q.maxAttempts,
      questionCount: q.questionCount,
      status: q.status,
      attemptsUsed: user.role === 'student' ? n : 0,
      submissionCount: user.role === 'teacher' ? n : 0,
      studentCount: studentsByCourse.get(q.courseId.toString()) ?? 0,
    };
  });
}

/** Quiz complet pour l'enseignant, bonnes réponses comprises. */
async function toFullQuiz(quiz: QuizDoc) {
  const questions = await Question.find({ quizId: quiz._id }).sort({ order: 1 }).lean();
  return {
    id: quiz._id.toString(),
    courseId: quiz.courseId.toString(),
    title: quiz.title,
    durationMinutes: quiz.durationMinutes,
    maxAttempts: quiz.maxAttempts,
    status: quiz.status,
    questions: questions.map((q) => ({
      id: q._id.toString(),
      text: q.text ?? '',
      options: q.options,
      correctIndex: q.correctIndex ?? null,
      explanation: q.explanation ?? '',
    })),
  };
}

// ---------------------------------------------------------------------------
// Listes
// ---------------------------------------------------------------------------

export async function listCourseQuizzes(user: AuthUser, courseId: string, query: ListQuery) {
  await findAccessibleCourse(courseId, user);
  const filter: Record<string, unknown> = { courseId };
  // L'étudiant ne voit jamais les brouillons.
  if (user.role === 'student') filter.status = query.status && query.status !== 'draft' ? query.status : { $ne: 'draft' };
  else if (query.status) filter.status = query.status;

  const [quizzes, total] = await Promise.all([
    Quiz.find(filter).sort({ createdAt: -1 }).skip(skipFor(query)).limit(query.limit),
    Quiz.countDocuments(filter),
  ]);
  return paginate(await toSummaries(quizzes, user), total, query);
}

export async function listMyQuizzes(user: AuthUser, query: ListQuery) {
  if (user.role === 'teacher') {
    const filter = { teacherId: user.id, ...(query.status ? { status: query.status } : {}) };
    const [quizzes, total] = await Promise.all([
      Quiz.find(filter).sort({ createdAt: -1 }).skip(skipFor(query)).limit(query.limit),
      Quiz.countDocuments(filter),
    ]);
    return paginate(await toSummaries(quizzes, user), total, query);
  }

  // Étudiant : quiz publiés de ses cours.
  const courseIds = await studentCourseIds(user.id);
  const filter: Record<string, unknown> = {
    courseId: { $in: courseIds },
    status: query.todo ? 'open' : query.status && query.status !== 'draft' ? query.status : { $ne: 'draft' },
  };
  const quizzes = await Quiz.find(filter).sort({ createdAt: -1 });
  let summaries = await toSummaries(quizzes, user);
  // « À faire » : il reste au moins une tentative (calcul qui dépend des tentatives,
  // donc fait après la requête ; le nombre de quiz par étudiant reste petit).
  if (query.todo) summaries = summaries.filter((q) => q.attemptsUsed < q.maxAttempts);
  const start = skipFor(query);
  return paginate(summaries.slice(start, start + query.limit), summaries.length, query);
}

// ---------------------------------------------------------------------------
// Création, édition, publication
// ---------------------------------------------------------------------------

async function replaceQuestions(quizId: Types.ObjectId, questions: QuizDraftInput['questions']) {
  await Question.deleteMany({ quizId });
  if (questions.length > 0) {
    await Question.insertMany(questions.map((q, order) => ({ ...q, quizId, order })));
  }
}

export async function create(user: AuthUser, courseId: string, input: QuizDraftInput) {
  const course = await findOwnedCourse(courseId, user.id);
  const quiz = await Quiz.create({
    courseId: course._id,
    teacherId: user.id,
    title: input.title,
    durationMinutes: input.durationMinutes,
    maxAttempts: input.maxAttempts,
    questionCount: input.questions.length,
  });
  await replaceQuestions(quiz._id, input.questions);
  return toFullQuiz(quiz);
}

export async function getFull(user: AuthUser, quizId: string) {
  return toFullQuiz(await findOwnedQuiz(quizId, user.id));
}

export async function update(user: AuthUser, quizId: string, input: QuizDraftInput) {
  const quiz = await findOwnedQuiz(quizId, user.id);
  // Modifier un quiz déjà passé fausserait les notes : seuls les brouillons changent.
  if (quiz.status !== 'draft') throw conflict('Un quiz publié ne peut plus être modifié', 'QUIZ_PUBLISHED');

  quiz.set({
    title: input.title,
    durationMinutes: input.durationMinutes,
    maxAttempts: input.maxAttempts,
    questionCount: input.questions.length,
  });
  await quiz.save();
  await replaceQuestions(quiz._id, input.questions);
  return toFullQuiz(quiz);
}

export async function publish(user: AuthUser, quizId: string) {
  const quiz = await findOwnedQuiz(quizId, user.id);
  if (quiz.status !== 'draft') throw conflict('Ce quiz est déjà publié', 'QUIZ_PUBLISHED');

  const questions = await Question.find({ quizId: quiz._id }).sort({ order: 1 }).lean();
  const problems = questions.flatMap((q, i) =>
    q.text?.trim() &&
    q.options.length === OPTION_COUNT &&
    q.options.every((o) => o.trim()) &&
    q.correctIndex !== null &&
    q.correctIndex !== undefined
      ? []
      : [`Question ${i + 1} incomplète`],
  );
  if (questions.length === 0) problems.push('Ajoute au moins une question');
  if (problems.length > 0) throw unprocessable(problems[0], { questions: problems }, 'QUIZ_INCOMPLETE');

  // Mise à jour conditionnelle : deux publications simultanées → une seule réussit.
  const published = await Quiz.findOneAndUpdate(
    { _id: quiz._id, status: 'draft' },
    { status: 'open', publishedAt: new Date() },
    { returnDocument: 'after' },
  );
  if (!published) throw conflict('Ce quiz est déjà publié', 'QUIZ_PUBLISHED');
  return (await toSummaries([published], user))[0];
}

export async function close(user: AuthUser, quizId: string) {
  const quiz = await findOwnedQuiz(quizId, user.id);
  if (quiz.status !== 'open') throw conflict('Seul un quiz ouvert peut être fermé', 'QUIZ_NOT_OPEN');
  quiz.set({ status: 'closed', closedAt: new Date() });
  await quiz.save();
  return (await toSummaries([quiz], user))[0];
}

// ---------------------------------------------------------------------------
// Rapport (écran 08)
// ---------------------------------------------------------------------------

export async function report(user: AuthUser, quizId: string) {
  const quiz = await findOwnedQuiz(quizId, user.id);
  await finalizeExpiredAttempts({ quizId: quiz._id });

  const [course, questions, studentCount, best] = await Promise.all([
    Course.findById(quiz.courseId).select('name').lean(),
    Question.find({ quizId: quiz._id }).sort({ order: 1 }).lean(),
    Enrollment.countDocuments({ courseId: quiz.courseId }),
    // Meilleure tentative de chaque étudiant : score décroissant, puis durée croissante.
    Attempt.aggregate<{
      attemptId: Types.ObjectId;
      studentId: Types.ObjectId;
      score: number;
      total: number;
      durationSeconds: number;
      expiresAt: Date;
      answers: { questionId: Types.ObjectId; optionIndex: number; answeredAt: Date }[];
    }>([
      { $match: { quizId: quiz._id, status: 'submitted' } },
      { $sort: { score: -1, durationSeconds: 1 } },
      {
        $group: {
          _id: '$studentId',
          attemptId: { $first: '$_id' },
          score: { $first: '$score' },
          total: { $first: '$total' },
          durationSeconds: { $first: '$durationSeconds' },
          answers: { $first: '$answers' },
          expiresAt: { $first: '$expiresAt' },
        },
      },
      { $addFields: { studentId: '$_id' } },
      { $sort: { score: -1, durationSeconds: 1 } },
    ]),
  ]);

  const names = new Map(
    (
      await User.find({ _id: { $in: best.map((b) => b.studentId) } })
        .select('name')
        .lean()
    ).map((u) => [u._id.toString(), u.name]),
  );

  // Même règle que la correction : dernière réponse donnée avant la fin du temps.
  const chosenByAttempt = best.map((b) => lastAnswers(b.answers, b.expiresAt));
  const questionStats = questions.map((q, index) => {
    let answered = 0;
    let correct = 0;
    for (const chosen of chosenByAttempt) {
      const pick = chosen.get(q._id.toString());
      if (pick !== undefined) {
        answered++;
        if (pick === q.correctIndex) correct++;
      }
    }
    return { index, text: q.text ?? '', correctCount: correct, answeredCount: answered };
  });

  const average = best.length === 0 ? 0 : best.reduce((sum, b) => sum + b.score, 0) / best.length;

  return {
    quizId: quiz._id.toString(),
    title: quiz.title,
    courseName: course?.name ?? '',
    status: quiz.status,
    questionCount: questions.length,
    studentCount,
    average: Math.round(average * 10) / 10,
    questions: questionStats,
    submissions: best.map((b) => ({
      attemptId: b.attemptId.toString(),
      studentName: names.get(b.studentId.toString()) ?? 'Étudiant',
      score: b.score,
      total: b.total,
      durationSeconds: b.durationSeconds,
    })),
  };
}

const toId = (id: string) => new Types.ObjectId(id);
