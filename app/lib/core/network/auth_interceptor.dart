import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Ajoute le jeton d'accès à chaque requête et le rafraîchit sur 401.
///
/// F6 — rafraîchissement sûr en concurrence : si trois requêtes reçoivent 401
/// en même temps, une seule appelle `/auth/refresh` ; les deux autres
/// attendent le même [Future] puis rejouent leur requête avec le nouveau jeton.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._storage, required this._refreshClient, required this._retryClient});

  final TokenStorage _storage;

  /// Dio sans intercepteur, pour appeler /auth/refresh sans boucle infinie.
  final Dio _refreshClient;

  /// Dio principal, pour rejouer la requête d'origine.
  final Dio _retryClient;

  /// Rafraîchissement en cours, partagé par toutes les requêtes en échec.
  Future<String?>? _refreshing;

  final _sessionExpired = StreamController<void>.broadcast();

  /// Émis quand le refresh échoue : l'utilisateur doit se reconnecter.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  static const _retriedKey = 'auth_retried';
  static const _skipAuthPaths = ['/auth/login', '/auth/register', '/auth/refresh'];

  bool _isAuthPath(RequestOptions o) => _skipAuthPaths.any(o.path.endsWith);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isAuthPath(options)) {
      final token = await _storage.accessToken;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final alreadyRetried = options.extra[_retriedKey] == true;

    if (err.response?.statusCode != 401 || _isAuthPath(options) || alreadyRetried) {
      return handler.next(err);
    }

    final newToken = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
    if (newToken == null) return handler.next(err);

    try {
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer $newToken';
      final response = await _retryClient.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Échange le refresh token contre une nouvelle paire (rotation côté serveur).
  Future<String?> _refresh() async {
    final refreshToken = await _storage.refreshToken;
    if (refreshToken == null) {
      _sessionExpired.add(null);
      return null;
    }
    try {
      final res = await _refreshClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data!;
      final access = data['accessToken'] as String;
      await _storage.save(accessToken: access, refreshToken: data['refreshToken'] as String);
      return access;
    } on DioException catch (e) {
      // Réseau coupé : on garde la session, la requête échouera en NetworkFailure.
      if (e.response == null) return null;
      await _storage.clear();
      _sessionExpired.add(null);
      return null;
    }
  }
}
