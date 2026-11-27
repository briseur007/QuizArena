part of 'quiz_play_bloc.dart';

enum PlayStatus { loading, loadFailure, inProgress, submitting, submitted }

final class QuizPlayState extends Equatable {
  const QuizPlayState({
    this.status = PlayStatus.loading,
    this.attempt,
    this.currentIndex = 0,
    this.answers = const {},
    this.saved = const {},
    this.remaining = Duration.zero,
    this.autoSubmitted = false,
    this.resultId,
    this.message,
  });

  final PlayStatus status;
  final Attempt? attempt;
  final int currentIndex;

  /// Réponses affichées (questionId → index de l'option), y compris optimistes.
  final Map<String, int> answers;

  /// Questions dont la réponse est confirmée par le serveur.
  final Set<String> saved;
  final Duration remaining;
  final bool autoSubmitted;

  /// Identifiant de la tentative corrigée, pour ouvrir l'écran Résultats.
  final String? resultId;

  /// Message ponctuel (SnackBar) ou erreur de chargement.
  final String? message;

  AttemptQuestion? get currentQuestion => attempt?.questions[currentIndex];
  int get questionCount => attempt?.questions.length ?? 0;
  bool get isLastQuestion => currentIndex == questionCount - 1;
  int? get selectedOption => currentQuestion == null ? null : answers[currentQuestion!.id];

  /// Moins d'une minute : le minuteur passe en alerte.
  bool get isRunningOut => remaining < const Duration(minutes: 1);

  QuizPlayState copyWith({
    PlayStatus? status,
    int? currentIndex,
    Map<String, int>? answers,
    Set<String>? saved,
    Duration? remaining,
    bool? autoSubmitted,
    String? resultId,
    String? message,
  }) => QuizPlayState(
    status: status ?? this.status,
    attempt: attempt,
    currentIndex: currentIndex ?? this.currentIndex,
    answers: answers ?? this.answers,
    saved: saved ?? this.saved,
    remaining: remaining ?? this.remaining,
    autoSubmitted: autoSubmitted ?? this.autoSubmitted,
    resultId: resultId ?? this.resultId,
    message: message,
  );

  @override
  List<Object?> get props => [
    status,
    attempt,
    currentIndex,
    answers,
    saved,
    remaining,
    autoSubmitted,
    resultId,
    message,
  ];
}
