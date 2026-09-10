import 'package:url_launcher/url_launcher.dart';

bool isSafeExternalUri(Uri uri) {
  return uri.scheme == 'http' || uri.scheme == 'https';
}

bool isSafeYoutubeUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || !isSafeExternalUri(uri)) return false;
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  return host == 'youtube.com' ||
      host == 'youtu.be' ||
      host == 'm.youtube.com' ||
      host == 'youtube-nocookie.com';
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
