import 'package:equatable/equatable.dart';

/// Écran 04 · Résultats d'une tentative corrigée par le serveur.
class AttemptResult extends Equatable {
  const AttemptResult({
    required this.id,
    required this.quizId,
    required this.courseId,
    required this.quizTitle,
    required this.courseName,
    required this.studentName,
    required this.score,
    required this.total,
    required this.durationSeconds,
    required this.attemptNumber,
    required this.maxAttempts,
    required this.corrections,
  });

  final String id;
  final String quizId;
  final String courseId;
  final String quizTitle;
  final String courseName;
  final String studentName;
  final int score;
  final int total;
  final int durationSeconds;
  final int attemptNumber;
  final int maxAttempts;
  final List<Correction> corrections;

  double get ratio => total == 0 ? 0 : score / total;

  @override
  List<Object?> get props => [
    id,
    quizId,
    courseId,
    quizTitle,
    courseName,
    studentName,
    score,
    total,
    durationSeconds,
    attemptNumber,
    maxAttempts,
    corrections,
  ];
}

class Correction extends Equatable {
  const Correction({
    required this.index,
    required this.question,
    required this.isCorrect,
    required this.correctAnswer,
    this.chosenAnswer,
    this.explanation,
  });

  final int index;
  final String question;

  /// `null` si l'étudiant n'a pas répondu.
  final String? chosenAnswer;
  final bool isCorrect;
  final String correctAnswer;
  final String? explanation;

  @override
  List<Object?> get props => [index, question, chosenAnswer, isCorrect, correctAnswer, explanation];
}
