import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Fabrique les clients Dio de l'application.
abstract final class ApiClient {
  static BaseOptions get _options => BaseOptions(
    baseUrl: AppConfig.apiUrl, // F13 : vient de --dart-define
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
  );

  static Dio create() => Dio(_options);
}
