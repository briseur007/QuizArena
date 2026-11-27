import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/attempt.dart';
import '../../domain/repositories/attempt_repository.dart';

part 'quiz_play_event.dart';
part 'quiz_play_state.dart';

/// Écran 03 · Quiz en cours.
///
/// - Minuteur : l'heure de fin vient du serveur ([Attempt.expiresAt]) ; le
///   téléphone ne fait qu'afficher le temps restant. À zéro, envoi automatique.
///   Le serveur refuse de toute façon les réponses arrivées après l'heure.
/// - F8, mise à jour optimiste : la réponse choisie s'affiche tout de suite,
///   est enregistrée sur le serveur, et revient en arrière si l'envoi échoue.
/// - Transformers : `sequential` pour les réponses (le serveur les reçoit
///   dans l'ordre des appuis), `droppable` pour l'envoi (pas de double remise).
class QuizPlayBloc extends Bloc<QuizPlayEvent, QuizPlayState> {
  QuizPlayBloc(this._repository, {DateTime Function()? now, Stream<void> Function()? ticker})
    : _now = now ?? DateTime.now,
      _ticker = ticker ?? (() => Stream<void>.periodic(const Duration(seconds: 1))),
      super(const QuizPlayState()) {
    on<PlayStarted>(_onStarted, transformer: droppable());
    on<PlayAnswerSelected>(_onAnswerSelected, transformer: sequential());
    on<PlayQuestionChanged>(_onQuestionChanged);
    on<PlaySubmitted>(_onSubmitted, transformer: droppable());
    on<_PlayTicked>(_onTicked);
  }

  final AttemptRepository _repository;
  final DateTime Function() _now;
  final Stream<void> Function() _ticker;
  StreamSubscription<void>? _tick;

  Future<void> _onStarted(PlayStarted event, Emitter<QuizPlayState> emit) async {
    emit(const QuizPlayState());
    final result = await _repository.start(event.quizId);
    switch (result) {
      case Ok(value: final attempt):
        emit(
          QuizPlayState(
            status: PlayStatus.inProgress,
            attempt: attempt,
            answers: attempt.savedAnswers,
            saved: attempt.savedAnswers.keys.toSet(),
            remaining: attempt.remainingAt(_now()),
          ),
        );
        _tick = _ticker().listen((_) => add(const _PlayTicked()));
        if (state.remaining == Duration.zero) add(const PlaySubmitted(auto: true));
      case Err(:final failure):
        emit(QuizPlayState(status: PlayStatus.loadFailure, message: failure.message));
    }
  }

  Future<void> _onAnswerSelected(PlayAnswerSelected event, Emitter<QuizPlayState> emit) async {
    final attempt = state.attempt;
    if (attempt == null || state.status != PlayStatus.inProgress) return;

    final questionId = state.currentQuestion!.id;
    final previous = state.answers[questionId];
    if (previous == event.optionIndex) return;

    // 1. Optimiste : on affiche le choix immédiatement.
    emit(
      state.copyWith(
        answers: {...state.answers, questionId: event.optionIndex},
        saved: {...state.saved}..remove(questionId),
      ),
    );

    // 2. Enregistrement sur le serveur.
    final result = await _repository.saveAnswer(
      attemptId: attempt.id,
      questionId: questionId,
      optionIndex: event.optionIndex,
    );

    switch (result) {
      case Ok():
        emit(state.copyWith(saved: {...state.saved, questionId}));
      case Err(:final failure):
        // 3. Rollback : on revient à la réponse précédente.
        final answers = {...state.answers}..remove(questionId);
        if (previous != null) answers[questionId] = previous;
        emit(
          state.copyWith(
            answers: answers,
            saved: previous != null ? {...state.saved, questionId} : state.saved,
            message: 'Réponse non enregistrée : ${failure.message}',
          ),
        );
    }
  }

  void _onQuestionChanged(PlayQuestionChanged event, Emitter<QuizPlayState> emit) {
    final count = state.attempt?.questions.length ?? 0;
    if (event.index < 0 || event.index >= count) return;
    emit(state.copyWith(currentIndex: event.index));
  }

  Future<void> _onSubmitted(PlaySubmitted event, Emitter<QuizPlayState> emit) async {
    final attempt = state.attempt;
    if (attempt == null || state.status != PlayStatus.inProgress) return;

    emit(state.copyWith(status: PlayStatus.submitting, autoSubmitted: event.auto));
    final result = await _repository.submit(attemptId: attempt.id, answers: state.answers);
    switch (result) {
      case Ok(:final value):
        await _tick?.cancel();
        emit(state.copyWith(status: PlayStatus.submitted, resultId: value.id));
      case Err(:final failure):
        emit(
          state.copyWith(
            status: PlayStatus.inProgress,
            message: 'Envoi impossible : ${failure.message} Tes réponses enregistrées sont conservées.',
          ),
        );
    }
  }

  void _onTicked(_PlayTicked event, Emitter<QuizPlayState> emit) {
    final attempt = state.attempt;
    if (attempt == null) return;
    final remaining = attempt.remainingAt(_now());
    emit(state.copyWith(remaining: remaining));
    // Un seul envoi automatique : s'il échoue (hors ligne), l'étudiant
    // réessaie avec le bouton, sans relance à chaque seconde.
    if (remaining == Duration.zero && state.status == PlayStatus.inProgress && !state.autoSubmitted) {
      add(const PlaySubmitted(auto: true));
    }
  }

  @override
  Future<void> close() async {
    await _tick?.cancel();
    return super.close();
  }
}
