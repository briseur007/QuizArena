part of 'quiz_play_bloc.dart';

sealed class QuizPlayEvent extends Equatable {
  const QuizPlayEvent();

  @override
  List<Object?> get props => [];
}

final class PlayStarted extends QuizPlayEvent {
  const PlayStarted(this.quizId);
  final String quizId;

  @override
  List<Object?> get props => [quizId];
}

/// Réponse choisie pour la question affichée.
final class PlayAnswerSelected extends QuizPlayEvent {
  const PlayAnswerSelected(this.optionIndex);
  final int optionIndex;

  @override
  List<Object?> get props => [optionIndex];
}

final class PlayQuestionChanged extends QuizPlayEvent {
  const PlayQuestionChanged(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

/// Remise du quiz : par l'étudiant, ou automatique ([auto]) à la fin du temps.
final class PlaySubmitted extends QuizPlayEvent {
  const PlaySubmitted({this.auto = false});
  final bool auto;

  @override
  List<Object?> get props => [auto];
}

/// Interne : une seconde s'est écoulée.
final class _PlayTicked extends QuizPlayEvent {
  const _PlayTicked();
}
