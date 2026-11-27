import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/quiz_report.dart';
import '../../domain/repositories/quiz_repository.dart';

enum ReportStatus { loading, success, failure }

final class QuizReportState extends Equatable {
  const QuizReportState({this.status = ReportStatus.loading, this.report, this.message});

  final ReportStatus status;
  final QuizReport? report;
  final String? message;

  @override
  List<Object?> get props => [status, report, message];
}

/// Écran 08 · Rapport du quiz (enseignant).
class QuizReportCubit extends Cubit<QuizReportState> {
  QuizReportCubit(this._repository) : super(const QuizReportState());

  final QuizRepository _repository;

  Future<void> load(String quizId) async {
    emit(const QuizReportState());
    final result = await _repository.report(quizId);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => QuizReportState(status: ReportStatus.success, report: value),
      Err(:final failure) => QuizReportState(status: ReportStatus.failure, message: failure.message),
    });
  }
}
