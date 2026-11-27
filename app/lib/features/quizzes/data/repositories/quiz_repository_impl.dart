import '../../../../core/error/result.dart';
import '../../../../core/network/api_error.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_report.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_data_source.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._remote);

  final QuizRemoteDataSource _remote;

  @override
  Future<Result<List<Quiz>>> courseQuizzes(String courseId) => guard(() => _remote.courseQuizzes(courseId));

  @override
  Future<Result<List<Quiz>>> myQuizzes({bool todo = false, QuizStatus? status}) =>
      guard(() => _remote.myQuizzes(todo: todo, status: status));

  @override
  Future<Result<QuizDraft>> getDraft(String quizId) => guard(() => _remote.getDraft(quizId));

  @override
  Future<Result<QuizDraft>> saveDraft(QuizDraft draft) =>
      guard(() => draft.isNew ? _remote.create(draft) : _remote.update(draft));

  @override
  Future<Result<Quiz>> publish(String quizId) => guard(() => _remote.publish(quizId));

  @override
  Future<Result<QuizReport>> report(String quizId) => guard(() => _remote.report(quizId));
}
