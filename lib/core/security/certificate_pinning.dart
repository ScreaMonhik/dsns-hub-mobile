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

void installPinnedHttpOverrides() {
  if (!AppConfig.isHttpsApi) {
    return;
  }
  HttpOverrides.global = _PinnedHttpOverrides();
}

class _PinnedHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => false;
    client.connectionFactory = (Uri url, String? proxyHost, int? proxyPort) async {
      if (url.scheme != 'https') {
        return ConnectionTask.fromSocket(
          Socket.connect(url.host, url.hasPort ? url.port : 80),
          () {},
        );
      }

      final port = url.hasPort ? url.port : 443;
      final socketFuture = SecureSocket.connect(
        url.host,
        port,
        context: SecurityContext(withTrustedRoots: true),
        onBadCertificate: (_) => false,
      ).then((socket) {
        final cert = socket.peerCertificate;
        if (cert == null) {
          socket.destroy();
          throw const HandshakeException('Missing peer certificate');
        }

        final actual = sha256.convert(cert.der).toString();
        final accepted = acceptPinnedCertificate(
          isRelease: kReleaseMode,
          pin: AppConfig.normalizedSslPin,
          actualHex: actual,
        );
        if (!accepted) {
          socket.destroy();
          throw const HandshakeException('SSL pin mismatch');
        }
        return socket;
      });

      return ConnectionTask.fromSocket(socketFuture, () {});
    };
    return client;
  }
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
