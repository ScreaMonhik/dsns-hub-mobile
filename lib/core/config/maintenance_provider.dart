import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../network/dio_provider.dart';
import 'maintenance.dart';

final maintenancePollerProvider = Provider<MaintenancePoller>((ref) {
  final poller = MaintenancePoller(ref);
  ref.onDispose(poller.dispose);
  return poller;
});

final maintenanceStatusProvider = ChangeNotifierProvider<MaintenanceStore>((ref) {
  ref.watch(maintenancePollerProvider);
  return MaintenanceStore.instance;
});

class MaintenancePoller {
  MaintenancePoller(this._ref) {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
  }

  final Ref _ref;
  Timer? _timer;
  bool _inFlight = false;

  Future<void> refresh() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final response = await _ref.read(dioProvider).get('/settings/status');
      MaintenanceStore.instance.applyFromJson(response.data);
    } catch (error, stack) {
      appLogger.w('Failed to fetch maintenance status', error: error, stackTrace: stack);
    } finally {
      _inFlight = false;
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
