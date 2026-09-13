class AppConfig {
  /// Override in CI / release: `--dart-define=API_BASE_URL=https://api.example.gov.ua`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// SHA-256 fingerprint of the government API TLS certificate (hex, optional colons).
  /// `--dart-define=SSL_PIN_SHA256=ab12cd...`
  static const String sslPinSha256 = String.fromEnvironment(
    'SSL_PIN_SHA256',
    defaultValue: '',
  );

  static const String androidPackageName = String.fromEnvironment(
    'ANDROID_PACKAGE_NAME',
    defaultValue: 'com.example.dsns_hub',
  );

  /// Base64 SHA-256 of the *release* signing certificate (freeRASP).
  static const String androidSigningCertHash = String.fromEnvironment(
    'ANDROID_CERT_HASH',
    defaultValue: '',
  );

  static const String iosBundleId = String.fromEnvironment(
    'IOS_BUNDLE_ID',
    defaultValue: 'com.example.dsnsHub',
  );

  static const String iosTeamId = String.fromEnvironment(
    'IOS_TEAM_ID',
    defaultValue: '',
  );

  static const String raspWatcherEmail = String.fromEnvironment(
    'RASP_WATCHER_EMAIL',
    defaultValue: 'development@buttonsos.com',
  );

  static bool get isHttpsApi => apiBaseUrl.startsWith('https://');

  static bool get hasSslPin => normalizedSslPin.isNotEmpty;

  static String get normalizedSslPin =>
      sslPinSha256.replaceAll(':', '').replaceAll(' ', '').toLowerCase();

  static bool get hasRaspSigningHash => androidSigningCertHash.trim().isNotEmpty;
}
