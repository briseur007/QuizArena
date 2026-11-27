part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

final class AuthState extends Equatable {
  const AuthState._({required this.status, this.user, this.sessionExpired = false, this.offline = false});

  /// Démarrage : la session n'a pas encore été vérifiée (écran de chargement).
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticated(User user) : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({bool sessionExpired = false, bool offline = false})
    : this._(status: AuthStatus.unauthenticated, sessionExpired: sessionExpired, offline: offline);

  final AuthStatus status;
  final User? user;
  final bool sessionExpired;
  final bool offline;

  @override
  List<Object?> get props => [status, user, sessionExpired, offline];
}
