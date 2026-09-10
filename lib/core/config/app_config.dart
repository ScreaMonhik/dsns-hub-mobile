class AppConfig {
  /// Override in CI / release: `--dart-define=API_BASE_URL=https://api.example.gov.ua`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
