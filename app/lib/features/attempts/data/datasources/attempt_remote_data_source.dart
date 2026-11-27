import 'package:dio/dio.dart';

import '../../domain/entities/attempt.dart';
import '../../domain/entities/attempt_result.dart';
import '../../domain/entities/leaderboard.dart';
import '../models/attempt_models.dart';

class AttemptRemoteDataSource {
  AttemptRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Attempt> start(String quizId) async {
    final res = await _dio.post<Map<String, dynamic>>('/quizzes/$quizId/attempts');
    return AttemptModel.fromJson(res.data!, receivedAt: DateTime.now());
  }

  Future<void> saveAnswer(String attemptId, String questionId, int optionIndex) async {
    await _dio.put<void>('/attempts/$attemptId/answers', data: {'questionId': questionId, 'optionIndex': optionIndex});
  }

  Future<AttemptResult> submit(String attemptId, Map<String, int> answers) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/attempts/$attemptId/submit',
      data: {
        'answers': [
          for (final e in answers.entries) {'questionId': e.key, 'optionIndex': e.value},
        ],
      },
    );
    return AttemptResultModel.fromJson(res.data!);
  }

  Future<AttemptResult> result(String attemptId) async {
    final res = await _dio.get<Map<String, dynamic>>('/attempts/$attemptId');
    return AttemptResultModel.fromJson(res.data!);
  }

  /// `null` si l'étudiant n'a encore remis aucun quiz (404).
  Future<AttemptResult?> latest() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/attempts/me/latest');
      return AttemptResultModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Leaderboard> leaderboard(LeaderboardScope scope, String id) async {
    final path = scope == LeaderboardScope.quiz ? '/quizzes/$id/leaderboard' : '/courses/$id/leaderboard';
    final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: {'limit': 50});
    return LeaderboardModel.fromJson(res.data!);
  }
}
