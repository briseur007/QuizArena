import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/storage/json_cache.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remote,
    required this._storage,
    required this._cache,
    required this._sessionExpired,
  });

  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;
  final JsonCache _cache;
  final Stream<void> _sessionExpired;

  static const _userKey = 'cache.user';

  @override
  Stream<void> get sessionExpired => _sessionExpired;

  @override
  Future<Result<User>> login({required String email, required String password}) {
    return guard(() async {
      final session = await _remote.login(email, password);
      await _saveSession(session);
      return session.user;
    });
  }

  @override
  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    return guard(() async {
      final session = await _remote.register(name, email, password, role);
      await _saveSession(session);
      return session.user;
    });
  }

  @override
  Future<Result<User>> currentUser() async {
    if (await _storage.refreshToken == null) return const Err(UnauthorizedFailure());

    final result = await guard(_remote.me);
    switch (result) {
      case Ok(:final value):
        await _cache.write(_userKey, UserModel.toJson(value));
        return result;
      case Err(failure: NetworkFailure()):
        // F9 : démarrage hors ligne, on reprend le dernier profil connu.
        final cached = await _cache.read<Map<String, dynamic>>(_userKey);
        return cached == null ? result : Ok(UserModel.fromJson(cached));
      case Err():
        return result;
    }
  }

  @override
  Future<Result<User>> updateProfile({String? name, String? email}) => guard(() async {
    final user = await _remote.updateMe(name: name, email: email);
    await _cache.write(_userKey, UserModel.toJson(user)); // profil hors ligne à jour
    return user;
  });

  @override
  Future<Result<void>> changePassword({required String currentPassword, required String newPassword}) =>
      guard(() => _remote.changePassword(currentPassword, newPassword));

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.refreshToken;
    try {
      if (refreshToken != null) await _remote.logout(refreshToken);
    } on DioException {
      // Hors ligne : la session expirera côté serveur ; on déconnecte localement.
    } finally {
      await _storage.clear();
      await _cache.clear(); // ne pas laisser les données d'un compte au suivant
    }
  }

  Future<void> _saveSession(AuthSession session) async {
    await _storage.save(accessToken: session.accessToken, refreshToken: session.refreshToken);
    await _cache.write(_userKey, UserModel.toJson(session.user));
  }
}
