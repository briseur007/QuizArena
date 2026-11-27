import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../error/result.dart';

/// Convertit une erreur Dio en [Failure], d'après le format unique de l'API :
/// `{ "error": { "code", "message", "details" } }`.
Failure mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const NetworkFailure();
    default:
      break;
  }

  final response = e.response;
  if (response == null) return const NetworkFailure();

  final body = response.data;
  final error = body is Map<String, dynamic> ? body['error'] : null;
  final message = error is Map<String, dynamic> ? error['message'] as String? : null;
  final code = error is Map<String, dynamic> ? error['code'] as String? : null;

  return switch (response.statusCode) {
    401 => const UnauthorizedFailure(),
    403 => message == null ? const ForbiddenFailure() : ForbiddenFailure(message),
    404 => message == null ? const NotFoundFailure() : NotFoundFailure(message),
    409 => ConflictFailure(message ?? 'Conflit.', code: code),
    422 => ValidationFailure(
      message ?? 'Données invalides.',
      fieldErrors: _fieldErrors(error is Map<String, dynamic> ? error['details'] : null),
    ),
    _ => const ServerFailure(),
  };
}

/// `details` = `{ "email": ["Email invalide"] }` (format `z.flattenError`).
/// On garde le premier message de chaque champ.
Map<String, String> _fieldErrors(Object? details) {
  if (details is! Map) return const {};
  final result = <String, String>{};
  details.forEach((key, value) {
    if (value is List && value.isNotEmpty) {
      result['$key'] = '${value.first}';
    } else if (value is String) {
      result['$key'] = value;
    }
  });
  return result;
}

/// Exécute un appel réseau et le transforme en [Result] (frontière data → domaine).
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on DioException catch (e) {
    return Err(mapDioError(e));
  } on FormatException {
    return const Err(ServerFailure('Réponse du serveur illisible.'));
  } on TypeError {
    return const Err(ServerFailure('Réponse du serveur inattendue.'));
  }
}
