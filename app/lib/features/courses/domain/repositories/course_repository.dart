import '../../../../core/error/result.dart';
import '../entities/course.dart';

abstract interface class CourseRepository {
  /// Dernière liste connue (cache local), ou `null` si jamais chargée.
  Future<List<Course>?> cachedCourses();

  /// Cours de l'utilisateur : rejoints (étudiant) ou créés (enseignant).
  /// Met à jour le cache en cas de succès.
  Future<Result<List<Course>>> fetchCourses();

  /// Étudiant : rejoindre un cours avec son code d'invitation.
  Future<Result<Course>> joinCourse(String code);

  /// Enseignant : créer un cours (le serveur génère le code).
  Future<Result<Course>> createCourse({required String name, required String level});
}
