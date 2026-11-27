import 'package:equatable/equatable.dart';

class Course extends Equatable {
  const Course({
    required this.id,
    required this.name,
    required this.level,
    required this.teacherName,
    required this.studentCount,
    required this.quizCount,
    this.code,
  });

  final String id;
  final String name;

  /// Niveau d'études (« L3 »).
  final String level;
  final String teacherName;
  final int studentCount;

  /// Étudiant : quiz ouverts. Enseignant : tous les quiz du cours.
  final int quizCount;

  /// Code d'invitation (« MOBL3A ») : renvoyé par l'API à l'enseignant uniquement.
  final String? code;

  @override
  List<Object?> get props => [id, name, level, teacherName, studentCount, quizCount, code];
}
