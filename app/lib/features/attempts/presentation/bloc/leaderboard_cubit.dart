import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/leaderboard.dart';
import '../../domain/repositories/attempt_repository.dart';

enum LeaderboardStatus { loading, success, empty, failure }

final class LeaderboardState extends Equatable {
  const LeaderboardState({
    this.status = LeaderboardStatus.loading,
    this.scope = LeaderboardScope.quiz,
    this.quizId,
    this.courseId,
    this.leaderboard,
    this.message,
  });

  final LeaderboardStatus status;
  final LeaderboardScope scope;
  final String? quizId;
  final String? courseId;
  final Leaderboard? leaderboard;
  final String? message;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    LeaderboardScope? scope,
    String? quizId,
    String? courseId,
    Leaderboard? leaderboard,
    String? message,
  }) => LeaderboardState(
    status: status ?? this.status,
    scope: scope ?? this.scope,
    quizId: quizId ?? this.quizId,
    courseId: courseId ?? this.courseId,
    leaderboard: leaderboard ?? this.leaderboard,
    message: message,
  );

  @override
  List<Object?> get props => [status, scope, quizId, courseId, leaderboard, message];
}

/// Écran 05 · Classement, avec bascule « Ce quiz / Mon cours ».
class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(this._repository) : super(const LeaderboardState());

  final AttemptRepository _repository;

  /// Sans [quizId] (onglet Classement), on prend le dernier quiz remis.
  Future<void> load({String? quizId, String? courseId}) async {
    emit(const LeaderboardState());

    if (quizId == null || courseId == null) {
      final latest = await _repository.latestResult();
      switch (latest) {
        case Ok(value: final r?):
          quizId = r.quizId;
          courseId = r.courseId;
        case Ok():
          emit(state.copyWith(status: LeaderboardStatus.empty));
          return;
        case Err(:final failure):
          emit(state.copyWith(status: LeaderboardStatus.failure, message: failure.message));
          return;
      }
    }

    emit(state.copyWith(quizId: quizId, courseId: courseId));
    await _fetch();
  }

  Future<void> scopeChanged(LeaderboardScope scope) async {
    if (scope == state.scope || state.quizId == null) return;
    emit(state.copyWith(scope: scope, status: LeaderboardStatus.loading));
    await _fetch();
  }

  Future<void> retry() => state.quizId == null ? load() : _fetch();

  Future<void> _fetch() async {
    final id = state.scope == LeaderboardScope.quiz ? state.quizId! : state.courseId!;
    emit(state.copyWith(status: LeaderboardStatus.loading));
    final result = await _repository.leaderboard(state.scope, id);
    if (isClosed) return;
    switch (result) {
      case Ok(:final value) when value.entries.isEmpty:
        emit(state.copyWith(status: LeaderboardStatus.empty, leaderboard: value));
      case Ok(:final value):
        emit(state.copyWith(status: LeaderboardStatus.success, leaderboard: value));
      case Err(:final failure):
        emit(state.copyWith(status: LeaderboardStatus.failure, message: failure.message));
    }
  }
}
