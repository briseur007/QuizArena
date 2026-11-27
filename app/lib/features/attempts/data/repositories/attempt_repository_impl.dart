import '../../../../core/error/result.dart';
import '../../../../core/network/api_error.dart';
import '../../domain/entities/attempt.dart';
import '../../domain/entities/attempt_result.dart';
import '../../domain/entities/leaderboard.dart';
import '../../domain/repositories/attempt_repository.dart';
import '../datasources/attempt_remote_data_source.dart';

class AttemptRepositoryImpl implements AttemptRepository {
  AttemptRepositoryImpl(this._remote);

  final AttemptRemoteDataSource _remote;

  @override
  Future<Result<Attempt>> start(String quizId) => guard(() => _remote.start(quizId));

  @override
  Future<Result<void>> saveAnswer({required String attemptId, required String questionId, required int optionIndex}) =>
      guard(() => _remote.saveAnswer(attemptId, questionId, optionIndex));

  @override
  Future<Result<AttemptResult>> submit({required String attemptId, required Map<String, int> answers}) =>
      guard(() => _remote.submit(attemptId, answers));

  @override
  Future<Result<AttemptResult>> result(String attemptId) => guard(() => _remote.result(attemptId));

  @override
  Future<Result<AttemptResult?>> latestResult() => guard(_remote.latest);

  @override
  Future<Result<Leaderboard>> leaderboard(LeaderboardScope scope, String id) =>
      guard(() => _remote.leaderboard(scope, id));
}
