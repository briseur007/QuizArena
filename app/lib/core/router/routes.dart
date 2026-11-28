/// Chemins de navigation de l'application.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // Onglets (barre de navigation du bas).
  static const home = '/home';
  static const ranking = '/ranking';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';

  // Étudiant.
  static String course(String courseId) => '/home/course/$courseId';
  static String play(String quizId) => '/play/$quizId';
  static String result(String attemptId) => '/home/result/$attemptId';
  static String leaderboard({required String quizId, required String courseId}) =>
      '/ranking?quizId=$quizId&courseId=$courseId';

  // Enseignant.
  static String newQuiz({required String courseId, required String courseName}) =>
      Uri(path: '/editor/new', queryParameters: {'courseId': courseId, 'courseName': courseName}).toString();
  static String editQuiz(String quizId, {required String courseId, required String courseName}) =>
      Uri(path: '/editor/$quizId', queryParameters: {'courseId': courseId, 'courseName': courseName}).toString();
  static String report(String quizId) => '/ranking/report/$quizId';
  static String submission(String quizId, String attemptId) => '/ranking/report/$quizId/attempt/$attemptId';

  /// Routes réservées aux enseignants (vérifiées par la garde du routeur).
  static bool isTeacherOnly(String location) =>
      location.startsWith('/editor') || location.startsWith('/ranking/report');

  static bool isStudentOnly(String location) =>
      location.startsWith('/play') || location.startsWith('/home/result') || location.startsWith('/home/course');
}
