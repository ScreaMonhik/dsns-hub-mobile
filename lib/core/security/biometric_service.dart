import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricLoginAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<IconData> getBiometricIcon() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.contains(BiometricType.face)) {
        return Icons.face_outlined;
      }
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return Icons.fingerprint;
      }
    } catch (_) {}
    return Icons.security;
  }

  static Future<bool> authenticate({
    bool biometricOnly = false,
    String localizedReason = 'Підтвердіть особу для доступу до системи DSNS Hub',
  }) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
      );
    } catch (_) {
      return false;
    }
  }
}
