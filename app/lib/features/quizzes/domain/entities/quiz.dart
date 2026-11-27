import 'package:equatable/equatable.dart';

enum QuizStatus {
  draft('BROUILLON'),
  open('OUVERT'),
  closed('FERMÉ');

  const QuizStatus(this.label);
  final String label;
}

/// Résumé d'un quiz, tel qu'affiché dans les listes.
class Quiz extends Equatable {
  const Quiz({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.durationMinutes,
    required this.maxAttempts,
    required this.questionCount,
    required this.status,
    this.courseLevel = '',
    this.attemptsUsed = 0,
    this.submissionCount = 0,
    this.studentCount = 0,
  });

  final String id;
  final String courseId;
  final String courseName;
  final String courseLevel;
  final String title;
  final int durationMinutes;
  final int maxAttempts;
  final int questionCount;
  final QuizStatus status;

  /// Étudiant : tentatives déjà utilisées.
  final int attemptsUsed;

  /// Enseignant : nombre de remises et d'inscrits au cours.
  final int submissionCount;
  final int studentCount;

  bool get canAttempt => status == QuizStatus.open && attemptsUsed < maxAttempts;

  @override
  List<Object?> get props => [
    id,
    courseId,
    courseName,
    courseLevel,
    title,
    durationMinutes,
    maxAttempts,
    questionCount,
    status,
    attemptsUsed,
    submissionCount,
    studentCount,
  ];
}
