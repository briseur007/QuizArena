import 'package:bloc/bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/attempt_result.dart';
import '../../domain/repositories/attempt_repository.dart';

/// Ligne « Dernier quiz : 8/10. Continue sur ta lancée ! » de l'écran 02.
/// Information secondaire : en cas d'erreur, la ligne est simplement masquée.
class LatestResultCubit extends Cubit<AttemptResult?> {
  LatestResultCubit(this._repository) : super(null);

  final AttemptRepository _repository;

  Future<void> load() async {
    final result = await _repository.latestResult();
    if (isClosed) return;
    if (result case Ok(:final value)) emit(value);
  }
}
