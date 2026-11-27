import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_arena/core/error/failure.dart';
import 'package:quiz_arena/core/network/api_error.dart';

DioException _response(int status, [Object? body]) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('mapDioError — format d’erreur unique de l’API', () {
    test('pas de réseau → NetworkFailure', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      expect(mapDioError(e), isA<NetworkFailure>());
    });

    test('422 → ValidationFailure avec le premier message de chaque champ', () {
      final failure = mapDioError(
        _response(422, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Données invalides',
            'details': {
              'email': ['Email invalide', 'Trop long'],
              'password': ['Requis'],
            },
          },
        }),
      );
      expect(
        failure,
        const ValidationFailure('Données invalides', fieldErrors: {'email': 'Email invalide', 'password': 'Requis'}),
      );
    });

    test('409 → ConflictFailure avec le code métier', () {
      final failure = mapDioError(
        _response(409, {
          'error': {'code': 'NO_ATTEMPT_LEFT', 'message': 'Tentatives épuisées.'},
        }),
      );
      expect(failure, const ConflictFailure('Tentatives épuisées.', code: 'NO_ATTEMPT_LEFT'));
    });

    test('403 / 404 / 500', () {
      expect(mapDioError(_response(403)), isA<ForbiddenFailure>());
      expect(mapDioError(_response(404)), isA<NotFoundFailure>());
      expect(mapDioError(_response(500, 'html inattendu')), isA<ServerFailure>());
    });
  });
}
