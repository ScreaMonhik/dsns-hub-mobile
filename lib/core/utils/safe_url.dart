import 'package:url_launcher/url_launcher.dart';

bool isSafeExternalUri(Uri uri) {
  return uri.scheme == 'http' || uri.scheme == 'https';
}

final _youtubeVideoId = RegExp(r'^[A-Za-z0-9_-]{11}$');
const _youtubeIdPathPrefixes = {'embed', 'shorts', 'live', 'v'};

bool isSafeYoutubeUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || !isSafeExternalUri(uri)) return false;
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  return host == 'youtube.com' ||
      host == 'youtu.be' ||
      host == 'm.youtube.com' ||
      host == 'youtube-nocookie.com';
}

/// Video id from watch / youtu.be / embed / shorts / live URLs, or null.
String? youtubeVideoId(String rawUrl) {
  if (!isSafeYoutubeUrl(rawUrl)) return null;
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return null;

  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
    final id = uri.pathSegments.first;
    return _youtubeVideoId.hasMatch(id) ? id : null;
  }

  final queryId = uri.queryParameters['v'];
  if (queryId != null && _youtubeVideoId.hasMatch(queryId)) return queryId;

  final segments = uri.pathSegments;
  for (var i = 0; i < segments.length - 1; i++) {
    if (_youtubeIdPathPrefixes.contains(segments[i])) {
      final id = segments[i + 1];
      if (_youtubeVideoId.hasMatch(id)) return id;
    }
  }
  return null;
}

String youtubeWatchUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return rawUrl;
  final segments = uri.pathSegments;
  if (segments.length >= 2 && segments.first == 'embed') {
    return Uri.https('www.youtube.com', '/watch', {
      'v': segments[1],
    }).toString();
  }
  return rawUrl;
}

Future<void> launchSafeUrl(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || !isSafeExternalUri(uri)) {
    return;
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> launchSafeYoutubeUrl(String rawUrl) async {
  if (!isSafeYoutubeUrl(rawUrl)) return;
  await launchSafeUrl(youtubeWatchUrl(rawUrl));
}
