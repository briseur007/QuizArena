import 'package:equatable/equatable.dart';

/// Question telle que l'étudiant la reçoit : SANS la bonne réponse
/// (règle serveur T17 : jamais envoyée avant la remise).
class AttemptQuestion extends Equatable {
  const AttemptQuestion({required this.id, required this.text, required this.options});

  final String id;
  final String text;
  final List<String> options;

  @override
  List<Object?> get props => [id, text, options];
}

/// Tentative en cours.
class Attempt extends Equatable {
  const Attempt({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.expiresAt,
    required this.questions,
    this.clockOffset = Duration.zero,
    this.savedAnswers = const {},
  });

  final String id;
  final String quizId;
  final String quizTitle;

  /// Fin de la tentative, fixée par le serveur au démarrage (minuteur serveur).
  final DateTime expiresAt;
  final List<AttemptQuestion> questions;

  /// Heure serveur − heure du téléphone : corrige une horloge mal réglée.
  final Duration clockOffset;

  /// Réponses déjà enregistrées (reprise après fermeture de l'app).
  final Map<String, int> savedAnswers;

  /// Temps restant à l'instant [now] (heure du téléphone).
  Duration remainingAt(DateTime now) {
    final left = expiresAt.difference(now.add(clockOffset));
    return left.isNegative ? Duration.zero : left;
  }

  @override
  List<Object?> get props => [id, quizId, quizTitle, expiresAt, questions, clockOffset, savedAnswers];
}
