import 'dart:convert';

import 'package:dsns_hub/core/security/jwt_utils.dart';
import 'package:flutter_test/flutter_test.dart';

String _unsignedJwt(Map<String, Object?> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}')).replaceAll('=', '');
  final body = base64Url.encode(utf8.encode(json.encode(payload))).replaceAll('=', '');
  return '$header.$body.sig';
}

void main() {
  group('JwtUtils', () {
    test('returns null for malformed tokens', () {
      expect(JwtUtils.decodePayload('not-a-jwt'), isNull);
      expect(JwtUtils.decodePayload('a.b'), isNull);
      expect(JwtUtils.decodePayload(''), isNull);
      expect(JwtUtils.userId('broken'), isNull);
      expect(JwtUtils.isExpired('broken'), isTrue);
    });

    test('reads sub as the user id', () {
      final token = _unsignedJwt({'sub': 'user-42', 'exp': 4102444800});
      expect(JwtUtils.userId(token), 'user-42');
      expect(JwtUtils.decodePayload(token)?['sub'], 'user-42');
    });

    test('treats a past exp as expired and a far-future exp as valid', () {
      final expired = _unsignedJwt({'sub': 'u', 'exp': 1});
      final living = _unsignedJwt({'sub': 'u', 'exp': 4102444800});
      expect(JwtUtils.isExpired(expired), isTrue);
      expect(JwtUtils.isExpired(living), isFalse);
    });

    test('does not throw on hostile payload bytes', () {
      expect(JwtUtils.decodePayload('aaa.%%%not-base64%%%.sig'), isNull);
    });
  });
}
