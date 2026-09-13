import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const defaultMaintenanceMessage =
    'Наразі проводяться технічні роботи. Спробуйте пізніше.';

const _maintenanceCacheKey = 'maintenance_status_cache';

class MaintenanceStatus {
  const MaintenanceStatus({
    required this.enabled,
    this.message = defaultMaintenanceMessage,
  });

  const MaintenanceStatus.inactive() : this(enabled: false);

  final bool enabled;
  final String message;
}

class MaintenanceStore extends ChangeNotifier {
  MaintenanceStore._();

  static final MaintenanceStore instance = MaintenanceStore._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  MaintenanceStatus status = const MaintenanceStatus.inactive();

  Future<void> restore() async {
    try {
      final raw = await _storage.read(key: _maintenanceCacheKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      applyFromJson(jsonDecode(raw));
    } catch (_) {}
  }

  void apply({required bool enabled, String? message}) {
    final next = MaintenanceStatus(
      enabled: enabled,
      message: (message != null && message.trim().isNotEmpty)
          ? message.trim()
          : defaultMaintenanceMessage,
    );
    if (status.enabled == next.enabled && status.message == next.message) {
      return;
    }
    status = next;
    notifyListeners();
    _persist();
  }

  void applyFromJson(Object? data) {
    final next = maintenanceStatusFromJson(data);
    apply(enabled: next.enabled, message: next.message);
  }

  Future<void> _persist() async {
    try {
      await _storage.write(
        key: _maintenanceCacheKey,
        value: jsonEncode({
          'maintenanceMode': status.enabled,
          'maintenanceMessage': status.message,
        }),
      );
    } catch (_) {}
  }
}

bool isMaintenanceResponse(DioException error) {
  final data = error.response?.data;
  if (error.response?.statusCode != 503 || data is! Map) {
    return false;
  }
  if (data['code'] == 'MAINTENANCE') {
    return true;
  }
  final message = data['message'];
  return message is String && message.contains('технічні роботи');
}

String maintenanceMessageFromError(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  }
  return defaultMaintenanceMessage;
}

MaintenanceStatus maintenanceStatusFromJson(Object? data) {
  if (data is! Map) {
    return const MaintenanceStatus.inactive();
  }
  final enabled = data['maintenanceMode'] == true;
  final rawMessage = data['maintenanceMessage'];
  final message = rawMessage is String && rawMessage.trim().isNotEmpty
      ? rawMessage.trim()
      : defaultMaintenanceMessage;
  return MaintenanceStatus(enabled: enabled, message: message);
}
