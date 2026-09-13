import 'package:dsns_hub/core/security/certificate_pinning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects missing pin in release', () {
    expect(
      acceptPinnedCertificate(isRelease: true, pin: '', actualHex: 'abc'),
      isFalse,
    );
  });

  test('allows missing pin in debug', () {
    expect(
      acceptPinnedCertificate(isRelease: false, pin: '', actualHex: 'abc'),
      isTrue,
    );
  });

  test('accepts an exact SHA-256 match', () {
    expect(
      acceptPinnedCertificate(isRelease: true, pin: 'deadbeef', actualHex: 'deadbeef'),
      isTrue,
    );
  });

  test('rejects a pin mismatch', () {
    expect(
      acceptPinnedCertificate(isRelease: true, pin: 'deadbeef', actualHex: 'cafebabe'),
      isFalse,
    );
  });

  test('rejects a case-shifted pin so hex must match exactly', () {
    expect(
      acceptPinnedCertificate(isRelease: true, pin: 'DEADBEEF', actualHex: 'deadbeef'),
      isFalse,
    );
  });
}
