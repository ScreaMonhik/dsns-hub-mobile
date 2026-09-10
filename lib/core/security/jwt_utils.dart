import 'dart:convert';

class JwtUtils {
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = json.decode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? userId(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;
    final id = payload['id'] ?? payload['sub'];
    return id?.toString();
  }

  static bool isExpired(
    String token, {
    Duration leeway = const Duration(seconds: 30),
  }) {
    final payload = decodePayload(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp is! num) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
    return DateTime.now().toUtc().isAfter(expiry.subtract(leeway));
  }
}
