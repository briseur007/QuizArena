/// F13 : l'URL de l'API vient de la configuration, jamais du code source.
///
/// flutter run --dart-define=API_URL=http://10.0.2.2:3000
class AppConfig {
  const AppConfig._();

  static const String apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');
}
