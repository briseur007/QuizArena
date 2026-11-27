import { randomInt } from 'node:crypto';
import type { Types } from 'mongoose';
import type { z } from 'zod';
import type { AuthUser } from '../../middlewares/auth.js';
import { conflict, notFound } from '../../middlewares/error.js';
import { paginate, skipFor } from '../../utils/validation.js';
import { User } from '../auth/user.model.js';
import { Quiz } from '../quizzes/quiz.model.js';
import { Course } from './course.model.js';
import type { createCourseBody, listCoursesQuery } from './courses.schemas.js';
import { Enrollment } from './enrollment.model.js';

type CourseDoc = InstanceType<typeof Course>;

export interface CourseDto {
  id: string;
  name: string;
  level: string;
  teacherName: string;
  studentCount: number;
  quizCount: number;
  code?: string;
}

// ---------------------------------------------------------------------------
// Contrôles d'accès réutilisés par les autres modules (A7, objet par objet).
// On renvoie 404 plutôt que 403 : un utilisateur extérieur au cours ne doit
// même pas apprendre qu'il existe.
// ---------------------------------------------------------------------------

/** Le cours appartient à cet enseignant. */
export async function findOwnedCourse(courseId: string, teacherId: string): Promise<CourseDoc> {
  const course = await Course.findOne({ _id: courseId, teacherId });
  if (!course) throw notFound('Cours introuvable');
  return course;
}

/** Enseignant propriétaire, ou étudiant inscrit. */
export async function findAccessibleCourse(courseId: string, user: AuthUser): Promise<CourseDoc> {
  const course = await Course.findById(courseId);
  if (!course) throw notFound('Cours introuvable');
  const allowed =
    user.role === 'teacher'
      ? course.teacherId.toString() === user.id
      : await Enrollment.exists({ courseId: course._id, studentId: user.id });
  if (!allowed) throw notFound('Cours introuvable');
  return course;
}

export async function isEnrolled(courseId: Types.ObjectId | string, studentId: string) {
  return Boolean(await Enrollment.exists({ courseId, studentId }));
}

export async function studentCourseIds(studentId: string): Promise<Types.ObjectId[]> {
  const rows = await Enrollment.find({ studentId }).select('courseId').lean();
  return rows.map((r) => r.courseId);
}

// ---------------------------------------------------------------------------

/** Ajoute aux cours les champs calculés affichés par l'app. */
export async function toCourseDtos(courses: CourseDoc[], viewer: AuthUser): Promise<CourseDto[]> {
  if (courses.length === 0) return [];
  const ids = courses.map((c) => c._id);

  const [teachers, students, quizzes] = await Promise.all([
    User.find({ _id: { $in: courses.map((c) => c.teacherId) } })
      .select('name')
      .lean(),
    Enrollment.aggregate<{ _id: Types.ObjectId; n: number }>([
      { $match: { courseId: { $in: ids } } },
      { $group: { _id: '$courseId', n: { $sum: 1 } } },
    ]),
    Quiz.aggregate<{ _id: Types.ObjectId; n: number }>([
      // L'étudiant ne compte que les quiz ouverts ; l'enseignant, tous ses quiz.
      { $match: { courseId: { $in: ids }, ...(viewer.role === 'student' ? { status: 'open' } : {}) } },
      { $group: { _id: '$courseId', n: { $sum: 1 } } },
    ]),
  ]);

  const teacherName = new Map(teachers.map((t) => [t._id.toString(), t.name]));
  const studentCount = new Map(students.map((s) => [s._id.toString(), s.n]));
  const quizCount = new Map(quizzes.map((q) => [q._id.toString(), q.n]));

  return courses.map((c) => {
    const id = c._id.toString();
    const isOwner = viewer.role === 'teacher' && c.teacherId.toString() === viewer.id;
    return {
      id,
      name: c.name,
      level: c.level ?? '',
      teacherName: teacherName.get(c.teacherId.toString()) ?? '',
      studentCount: studentCount.get(id) ?? 0,
      quizCount: quizCount.get(id) ?? 0,
      // Le code d'invitation n'est montré qu'à l'enseignant du cours.
      ...(isOwner ? { code: c.code } : {}),
    };
  });
}

export async function listMine(user: AuthUser, query: z.infer<typeof listCoursesQuery>) {
  const filter: Record<string, unknown> =
    user.role === 'teacher' ? { teacherId: user.id } : { _id: { $in: await studentCourseIds(user.id) } };
  if (query.q) filter.name = { $regex: escapeRegex(query.q), $options: 'i' };

  const [courses, total] = await Promise.all([
    Course.find(filter).sort({ createdAt: -1 }).skip(skipFor(query)).limit(query.limit),
    Course.countDocuments(filter),
  ]);
  return paginate(await toCourseDtos(courses, user), total, query);
}

export async function create(user: AuthUser, input: z.infer<typeof createCourseBody>) {
  // Code aléatoire ; en cas de collision (index unique), on réessaie.
  for (let attempt = 0; attempt < 5; attempt++) {
    try {
      const course = await Course.create({ ...input, teacherId: user.id, code: randomCode() });
      return (await toCourseDtos([course], user))[0];
    } catch (err) {
      if (!isDuplicateCode(err)) throw err;
    }
  }
  throw conflict('Impossible de générer un code unique, réessaie', 'CODE_COLLISION');
}

export async function join(user: AuthUser, code: string) {
  const course = await Course.findOne({ code });
  if (!course) throw notFound('Aucun cours avec ce code', 'COURSE_CODE_UNKNOWN');
  try {
    await Enrollment.create({ courseId: course._id, studentId: user.id });
  } catch (err) {
    if (isDuplicateKey(err)) throw conflict('Tu es déjà inscrit à ce cours', 'ALREADY_ENROLLED');
    throw err;
  }
  return (await toCourseDtos([course], user))[0];
}

// ---------------------------------------------------------------------------

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans 0/O ni 1/I

function randomCode(length = 6): string {
  return Array.from({ length }, () => CODE_ALPHABET[randomInt(CODE_ALPHABET.length)]).join('');
}

function isDuplicateKey(err: unknown): boolean {
  return typeof err === 'object' && err !== null && 'code' in err && err.code === 11000;
}

function isDuplicateCode(err: unknown): boolean {
  return isDuplicateKey(err) && JSON.stringify((err as { keyPattern?: unknown }).keyPattern ?? {}).includes('code');
}

export function escapeRegex(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
