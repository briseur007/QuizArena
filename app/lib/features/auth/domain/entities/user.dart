import 'package:equatable/equatable.dart';

enum UserRole {
  student('Étudiant'),
  teacher('Enseignant');

  const UserRole(this.label);
  final String label;
}

class User extends Equatable {
  const User({required this.id, required this.name, required this.email, required this.role, this.level = 1});

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// Niveau calculé par le serveur à partir des quiz réussis (« Niveau 4 »).
  final int level;

  bool get isTeacher => role == UserRole.teacher;

  @override
  List<Object?> get props => [id, name, email, role, level];
}
