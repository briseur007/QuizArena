import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';

enum QuizListStatus { initial, loading, success, failure }

final class QuizListState extends Equatable {
  const QuizListState({this.status = QuizListStatus.initial, this.quizzes = const [], this.message});

  final QuizListStatus status;
  final List<Quiz> quizzes;
  final String? message;

  bool get isEmpty => status == QuizListStatus.success && quizzes.isEmpty;

  @override
  List<Object?> get props => [status, quizzes, message];
}

/// Liste de quiz réutilisée par plusieurs écrans : quiz d'un cours,
/// « à faire » de l'étudiant, quiz publiés de l'enseignant.
class QuizListCubit extends Cubit<QuizListState> {
  QuizListCubit(this._repository) : super(const QuizListState());

  final QuizRepository _repository;
  Future<Result<List<Quiz>>> Function()? _lastQuery;

  Future<void> loadCourse(String courseId) => _load(() => _repository.courseQuizzes(courseId));

  Future<void> loadTodo() => _load(() => _repository.myQuizzes(todo: true));

  /// Enseignant : quiz publiés (ouverts puis fermés) pour l'onglet Résultats.
  Future<void> loadPublished() => _load(() async {
    final open = await _repository.myQuizzes(status: QuizStatus.open);
    final closed = await _repository.myQuizzes(status: QuizStatus.closed);
    return switch ((open, closed)) {
      (Ok(value: final a), Ok(value: final b)) => Ok([...a, ...b]),
      (Err(:final failure), _) || (_, Err(:final failure)) => Err(failure),
    };
  });

  Future<void> retry() async {
    final query = _lastQuery;
    if (query != null) await _load(query);
  }

  Future<void> _load(Future<Result<List<Quiz>>> Function() query) async {
    _lastQuery = query;
    emit(QuizListState(status: QuizListStatus.loading, quizzes: state.quizzes));
    final result = await query();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => QuizListState(status: QuizListStatus.success, quizzes: value),
      Err(:final failure) => QuizListState(status: QuizListStatus.failure, message: failure.message),
    });
  }
}
