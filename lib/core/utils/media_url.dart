import '../config/app_config.dart';

/// Resolves a TipTap/API media path to an http(s) URL, or null if unsafe.
String? resolveMediaUrl(String? rawUrl, {String? baseUrl}) {
  if (rawUrl == null) return null;
  final normalizedUrl = rawUrl.replaceAll('\\', '/').trim();
  if (normalizedUrl.isEmpty) return null;

  final uri = Uri.tryParse(normalizedUrl);
  if (uri == null) return null;

  if (uri.hasScheme) {
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return normalizedUrl;
  }

  if (normalizedUrl.startsWith('//')) return null;

  final origin = baseUrl ?? AppConfig.apiBaseUrl;
  final formattedPath = normalizedUrl.startsWith('/')
      ? normalizedUrl
      : '/$normalizedUrl';
  return '$origin$formattedPath';
}
