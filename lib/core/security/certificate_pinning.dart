import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';

bool acceptPinnedCertificate({
  required bool isRelease,
  required String pin,
  required String actualHex,
}) {
  if (pin.isEmpty) {
    return !isRelease;
  }
  return actualHex == pin;
}

void applyCertificatePinning(Dio dio) {
  if (!AppConfig.isHttpsApi) {
    appLogger.i('SSL pinning skipped: API uses HTTP');
    return;
  }

  final pin = AppConfig.normalizedSslPin;

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient(context: SecurityContext(withTrustedRoots: true));
      client.badCertificateCallback = (_, _, _) => false;
      return client;
    },
    validateCertificate: (cert, host, port) {
      if (cert == null) {
        return false;
      }

      final actual = sha256.convert(cert.der).toString();
      final accepted = acceptPinnedCertificate(
        isRelease: kReleaseMode,
        pin: pin,
        actualHex: actual,
      );
      if (!accepted) {
        appLogger.e(
          pin.isEmpty
              ? 'SSL pin is not configured for HTTPS host $host:$port'
              : 'SSL pin mismatch for $host:$port',
        );
      }
      return accepted;
    },
  );
}
