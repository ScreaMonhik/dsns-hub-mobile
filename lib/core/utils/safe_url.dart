import 'package:url_launcher/url_launcher.dart';

bool isSafeExternalUri(Uri uri) {
  return uri.scheme == 'http' || uri.scheme == 'https';
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
