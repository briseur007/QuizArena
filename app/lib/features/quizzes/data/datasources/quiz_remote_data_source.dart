import 'package:dio/dio.dart';

import '../../../../core/network/paginated.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_report.dart';
import '../models/quiz_models.dart';

class QuizRemoteDataSource {
  QuizRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Quiz>> courseQuizzes(String courseId) async {
    final res = await _dio.get<Map<String, dynamic>>('/courses/$courseId/quizzes', queryParameters: {'limit': 50});
    return Paginated.fromJson(res.data!, QuizModel.fromJson).items;
  }

  Future<List<Quiz>> myQuizzes({required bool todo, QuizStatus? status}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quizzes',
      queryParameters: {
        'limit': 50,
        if (todo) 'todo': true,
        if (status != null) 'status': QuizModel.statusToJson(status),
      },
    );
    return Paginated.fromJson(res.data!, QuizModel.fromJson).items;
  }

  Future<QuizDraft> getDraft(String quizId) async {
    final res = await _dio.get<Map<String, dynamic>>('/quizzes/$quizId');
    return QuizDraftModel.fromJson(res.data!);
  }

  Future<QuizDraft> create(QuizDraft draft) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/courses/${draft.courseId}/quizzes',
      data: QuizDraftModel.toJson(draft),
    );
    return QuizDraftModel.fromJson(res.data!);
  }

  Future<QuizDraft> update(QuizDraft draft) async {
    final res = await _dio.patch<Map<String, dynamic>>('/quizzes/${draft.id}', data: QuizDraftModel.toJson(draft));
    return QuizDraftModel.fromJson(res.data!);
  }

  Future<Quiz> publish(String quizId) async {
    final res = await _dio.post<Map<String, dynamic>>('/quizzes/$quizId/publish');
    return QuizModel.fromJson(res.data!);
  }

  Future<QuizReport> report(String quizId) async {
    final res = await _dio.get<Map<String, dynamic>>('/quizzes/$quizId/report');
    return QuizReportModel.fromJson(res.data!);
  }
}
