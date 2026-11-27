import '../../../../core/error/result.dart';
import '../entities/attempt.dart';
import '../entities/attempt_result.dart';
import '../entities/leaderboard.dart';

abstract interface class AttemptRepository {
  /// Démarre une tentative, ou reprend celle en cours. Le serveur refuse
  /// (409) si le nombre de tentatives autorisées est atteint.
  Future<Result<Attempt>> start(String quizId);

  /// Enregistre une réponse au fil de l'eau (refusée après expiration).
  Future<Result<void>> saveAnswer({required String attemptId, required String questionId, required int optionIndex});

  /// Remet la tentative : le serveur corrige et renvoie la note.
  Future<Result<AttemptResult>> submit({required String attemptId, required Map<String, int> answers});

  Future<Result<AttemptResult>> result(String attemptId);

  /// Dernier résultat de l'étudiant, ou `null` s'il n'a encore rien remis.
  Future<Result<AttemptResult?>> latestResult();

  Future<Result<Leaderboard>> leaderboard(LeaderboardScope scope, String id);
}
