import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/attempt_result.dart';
import '../../domain/repositories/attempt_repository.dart';

enum ResultStatus { loading, success, failure }

final class ResultState extends Equatable {
  const ResultState({this.status = ResultStatus.loading, this.result, this.message});

  final ResultStatus status;
  final AttemptResult? result;
  final String? message;

  @override
  List<Object?> get props => [status, result, message];
}

/// Écran 04 · Résultats (étudiant, ou enseignant qui consulte une remise).
class ResultCubit extends Cubit<ResultState> {
  ResultCubit(this._repository) : super(const ResultState());

  final AttemptRepository _repository;

  Future<void> load(String attemptId) async {
    emit(const ResultState());
    final result = await _repository.result(attemptId);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => ResultState(status: ResultStatus.success, result: value),
      Err(:final failure) => ResultState(status: ResultStatus.failure, message: failure.message),
    });
  }

  /// Appréciation affichée sous la note (« Bien joué, Amina ! »).
  static ({String title, String subtitle}) appreciation(double ratio, String firstName) {
    if (ratio >= 0.8) return (title: 'Bien joué, $firstName !', subtitle: 'Tu maîtrises les bases.');
    if (ratio >= 0.5) return (title: 'Pas mal, $firstName !', subtitle: 'Revois les questions manquées.');
    return (title: 'Courage, $firstName !', subtitle: 'Relis la correction pour progresser.');
  }
}
