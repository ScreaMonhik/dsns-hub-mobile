import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const defaultMaintenanceMessage =
    'Наразі проводяться технічні роботи. Спробуйте пізніше.';

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

  MaintenanceStatus status = const MaintenanceStatus.inactive();

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
  }

  void applyFromJson(Object? data) {
    final next = maintenanceStatusFromJson(data);
    apply(enabled: next.enabled, message: next.message);
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
