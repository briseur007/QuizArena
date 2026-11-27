import '../../../../core/error/result.dart';
import '../entities/user.dart';

/// Contrat d'authentification (F3) : implémenté dans la couche data.
abstract interface class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  /// Restaure la session au démarrage à partir des jetons stockés.
  /// Échoue avec `UnauthorizedFailure` s'il n'y a pas de session valide.
  Future<Result<User>> currentUser();

  /// Révoque la session côté serveur puis efface les jetons locaux.
  Future<void> logout();

  /// Émis quand le refresh token est refusé (session révoquée ou expirée).
  Stream<void> get sessionExpired;
}
