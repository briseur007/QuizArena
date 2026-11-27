import 'package:equatable/equatable.dart';

import 'quiz.dart';

/// Écran 08 · Rapport du quiz (calculé par le serveur).
class QuizReport extends Equatable {
  const QuizReport({
    required this.quizId,
    required this.title,
    required this.courseName,
    required this.status,
    required this.questionCount,
    required this.studentCount,
    required this.average,
    required this.questions,
    required this.submissions,
  });

  final String quizId;
  final String title;
  final String courseName;
  final QuizStatus status;
  final int questionCount;
  final int studentCount;

  /// Moyenne de la classe, sur [questionCount].
  final double average;
  final List<QuestionStat> questions;
  final List<Submission> submissions;

  int get submittedCount => submissions.length;
  int get missingCount => (studentCount - submittedCount).clamp(0, studentCount);

  @override
  List<Object?> get props => [
    quizId,
    title,
    courseName,
    status,
    questionCount,
    studentCount,
    average,
    questions,
    submissions,
  ];
}

class QuestionStat extends Equatable {
  const QuestionStat({
    required this.index,
    required this.text,
    required this.correctCount,
    required this.answeredCount,
  });

  final int index;
  final String text;
  final int correctCount;
  final int answeredCount;

  double get successRate => answeredCount == 0 ? 0 : correctCount / answeredCount;

  @override
  List<Object?> get props => [index, text, correctCount, answeredCount];
}

class Submission extends Equatable {
  const Submission({
    required this.attemptId,
    required this.studentName,
    required this.score,
    required this.total,
    required this.durationSeconds,
  });

  final String attemptId;
  final String studentName;
  final int score;
  final int total;
  final int durationSeconds;

  @override
  List<Object?> get props => [attemptId, studentName, score, total, durationSeconds];
}
