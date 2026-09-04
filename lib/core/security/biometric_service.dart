import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

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
    return Icons.security; // Фолбек, якщо тип не розпізнано
  }

  static Future<bool> authenticate() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!isSupported || !canCheck) {
        return true; // Дозволяємо вхід, якщо пристрій не підтримує біометрію, щоб уникнути блокування
      }

      return await _auth.authenticate(
        localizedReason: 'Підтвердіть особу для доступу до системи DSNS Hub',
      );
    } catch (e) {
      return false;
    }
  }
}