import 'package:dsns_hub/core/security/password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordRules', () {
    test('rejects empty, short, and common passwords', () {
      expect(PasswordRules.isValid(''), isFalse);
      expect(PasswordRules.isValid('Ab1!'), isFalse);
      expect(PasswordRules.isValid('password'), isFalse);
      expect(PasswordRules.isValid('Password1'), isFalse);
      expect(PasswordRules.isValid('password1!'), isFalse);
      expect(PasswordRules.isValid('PASSWORD1!'), isFalse);
    });

    test('accepts a password that meets complexity rules', () {
      expect(PasswordRules.isValid('Correct1!'), isTrue);
      expect(PasswordRules.isValid('DsnsHub9@'), isTrue);
    });

    test('rejects characters outside the allowed alphabet', () {
      expect(PasswordRules.isValid('Correct1! '), isFalse);
      expect(PasswordRules.isValid('Correct1#'), isFalse);
    });
  });
}
