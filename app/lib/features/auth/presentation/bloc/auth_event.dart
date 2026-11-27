part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Au démarrage : y a-t-il une session valide ?
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Envoyé par les formulaires de connexion / d'inscription.
final class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
