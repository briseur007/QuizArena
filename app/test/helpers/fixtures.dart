import 'package:quiz_arena/features/attempts/domain/entities/attempt.dart';
import 'package:quiz_arena/features/attempts/domain/entities/attempt_result.dart';
import 'package:quiz_arena/features/attempts/domain/entities/leaderboard.dart';
import 'package:quiz_arena/features/auth/domain/entities/user.dart';
import 'package:quiz_arena/features/courses/domain/entities/course.dart';
import 'package:quiz_arena/features/quizzes/domain/entities/quiz.dart';
import 'package:quiz_arena/features/quizzes/domain/entities/quiz_draft.dart';

/// Données de test partagées, inspirées de la maquette.
abstract final class Fx {
  static const student = User(id: 'u1', name: 'Amina Ouédraogo', email: 'amina@universite.bf', role: UserRole.student);
  static const teacher = User(id: 'u2', name: 'Dr Nikiema', email: 'nikiema@universite.bf', role: UserRole.teacher);

  static const mobile = Course(
    id: 'c1',
    name: 'Développement mobile',
    level: 'L3',
    teacherName: 'Dr Nikiema',
    studentCount: 32,
    quizCount: 3,
  );
  static const databases = Course(
    id: 'c2',
    name: 'Bases de données',
    level: 'L3',
    teacherName: 'Mme Traoré',
    studentCount: 28,
    quizCount: 1,
  );

  static const quiz = Quiz(
    id: 'q1',
    courseId: 'c1',
    courseName: 'Développement mobile',
    title: 'Flutter & BLoC',
    durationMinutes: 10,
    maxAttempts: 1,
    questionCount: 2,
    status: QuizStatus.open,
  );

  static final now = DateTime.utc(2026, 11, 27, 10);

  static Attempt attempt({Duration left = const Duration(minutes: 10), Map<String, int> saved = const {}}) => Attempt(
    id: 'a1',
    quizId: 'q1',
    quizTitle: 'Flutter & BLoC',
    expiresAt: now.add(left),
    savedAnswers: saved,
    questions: const [
      AttemptQuestion(id: 'qq1', text: 'Quel langage utilise Flutter ?', options: ['Dart', 'JS', 'Kotlin', 'Python']),
      AttemptQuestion(id: 'qq2', text: 'Rôle d’un BLoC ?', options: ['Dessiner', 'État', 'Stocker', 'Compiler']),
    ],
  );

  static const result = AttemptResult(
    id: 'a1',
    quizId: 'q1',
    courseId: 'c1',
    quizTitle: 'Flutter & BLoC',
    courseName: 'Développement mobile',
    studentName: 'Amina Ouédraogo',
    score: 8,
    total: 10,
    durationSeconds: 438,
    attemptNumber: 1,
    maxAttempts: 1,
    corrections: [],
  );

  static const leaderboard = Leaderboard(
    title: 'Flutter & BLoC',
    participants: 3,
    entries: [
      LeaderboardEntry(rank: 1, name: 'Fatou Ouédraogo', score: 10, total: 10, durationSeconds: 342),
      LeaderboardEntry(rank: 2, name: 'Ibrahim Traoré', score: 9, total: 10, durationSeconds: 375),
      LeaderboardEntry(rank: 3, name: 'Amina', score: 8, total: 10, durationSeconds: 438, isMe: true),
    ],
  );

  static const completeQuestion = QuestionDraft(
    text: 'Quel langage utilise Flutter ?',
    options: ['Dart', 'JavaScript', 'Kotlin', 'Python'],
    correctIndex: 0,
  );
}
