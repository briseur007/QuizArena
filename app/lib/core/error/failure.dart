import 'package:equatable/equatable.dart';

/// Erreur métier vue par le domaine et la présentation.
///
/// F3 : les exceptions (Dio, JSON…) sont converties en [Failure] une seule
/// fois, à la frontière de la couche data (voir `core/network/api_error.dart`).
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Pas de réseau, délai dépassé, serveur injoignable.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Connexion impossible. Vérifie ton réseau.']);
}

/// 401 : session absente ou expirée.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Ta session a expiré. Reconnecte-toi.']);
}

/// 403 : action interdite pour ce rôle ou cet objet.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = "Tu n'as pas accès à cette ressource."]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Élément introuvable.']);
}

/// 409 : conflit métier (déjà inscrit, tentative déjà utilisée…).
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {this.code});

  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// 422 : erreurs de validation, par champ (F10).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Une erreur est survenue. Réessaie.']);
}
